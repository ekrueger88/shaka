# frozen_string_literal: true

require 'json'
require 'optparse'
require_relative '../trusted_config_source'
require_relative '../local_review/path_guard'
require_relative 'judgment'
require_relative 'provider_runner'

module Shaka
  module RiskAssessment
    # The binding Shaka supplies around a judgment.
    module Inputs
      private

      def binding(identity, prompt, inputs)
        { 'head' => @options[:head], 'base' => @options[:base], 'policy_ref' => @policy_ref, 'prompt' => prompt,
          'runner' => { 'kind' => 'provider', 'identity' => identity, 'version' => 'UNKNOWN' },
          'model' => 'UNKNOWN', 'effort' => 'UNKNOWN', 'inputs' => inputs }
      end

      def inputs(coverage)
        list = ['diff']
        list << 'description' if @options[:description_file]
        list << 'source_lookup' if coverage&.start_with?('Read-only')
        list
      end

      # The evidence was just built from these inputs, so the decision checks completeness and tolerance.
      def expected(evidence)
        runner = evidence['runner']
        { 'head' => @options[:head], 'base' => @options[:base], 'policy_ref' => @policy_ref,
          'prompt_sha256' => evidence.dig('prompt', 'sha256'), 'runner' => "#{runner['kind']}:#{runner['identity']}" }
      end
    end

    # Where the candidate checkout is, and which programs may run beside it.
    module Boundary
      private

      # Before any Git call: candidate programs on PATH, such as a checkout's own bin/git, must not run,
      # and the Git that remains first must not hand off to a candidate-owned interpreter either.
      def screen_path!
        @options[:root] = checkout_top(@options[:root])
        ENV['PATH'] = LocalReviewPathGuard.safe_path(ENV.fetch('PATH', ''), candidate_root: @options[:root],
                                                                            drop_candidate: true)
        LocalReviewPathGuard.safe_executable(ENV.fetch('PATH'), 'git', @options[:root]) ||
          raise(Error, 'git is not on PATH')
      end

      # Boundaries compare against the real checkout top, whatever spelling or subdirectory --root used.
      # Found from the filesystem, because no program on PATH is trusted yet.
      def checkout_top(root)
        directory = File.realpath(root)
        directory = File.dirname(directory) until File.exist?(File.join(directory, '.git')) ||
                                                  directory == File.dirname(directory)
        raise Error, '--root is not inside a Git checkout' unless File.exist?(File.join(directory, '.git'))

        directory
      end
    end

    # `shaka risk assess`: rates one committed change with the trusted settings' classifier and
    # prints the bound evidence with its shadow decision. Disabled settings make no call.
    class Command
      include Inputs
      include Boundary

      ACTIONS = %w[assess].freeze
      FLAGS = { root: 'root', base: 'base', head: 'head', description_file: 'description-file',
                timeout_seconds: 'timeout-seconds', repository: 'repository' }.freeze

      def self.run(arguments)
        result = new(arguments).run
        puts JSON.pretty_generate(result)
        %w[completed disabled].include?(result['status']) ? 0 : 1
      rescue OptionParser::ParseError, SystemCallError, Error => e
        warn "shaka: #{e.message}"
        1
      end

      def initialize(arguments)
        @arguments = arguments.dup
        @options = {}
      end

      def run
        action = @arguments.shift
        raise Error, "Usage: shaka risk (#{ACTIONS.join('|')}) [options]" unless ACTIONS.include?(action)

        parser.parse!(@arguments)
        validate_options!
        screen_path!
        assess
      end

      private

      def validate_options!
        %i[root base head criteria_ref].each do |key|
          raise Error, "Missing --#{key.to_s.tr('_', '-')}" unless @options[key]
        end
        %i[base head criteria_ref].each do |key|
          raise Error, "--#{key.to_s.tr('_', '-')} must be a full commit SHA" unless @options[key].match?(SHA)
        end
      end

      def assess
        config = TrustedConfigSource.load(root: @options[:root], ref: @options[:criteria_ref],
                                          candidate_commands: false)
        @settings = config.risk_assessment
        return { 'status' => 'disabled', 'reason' => 'risk_assessment.enabled is false' } unless @settings['enabled']

        @policy_ref = config.sha
        finish(provider_outcome)
      end

      def finish(outcome)
        return outcome.merge('status' => 'not_completed') unless outcome['judgment']

        evidence = Judgment.evidence(outcome.delete('judgment'), outcome.delete('binding'))
        decision = RiskAssessment.decide(evidence, expected: expected(evidence), tolerance: @settings['auto_max_risk'])
        outcome.merge('status' => 'completed', 'evidence' => evidence, 'decision' => decision)
      rescue Error => e
        outcome.except('judgment', 'binding').merge('status' => 'not_completed', 'reason' => e.message)
      end

      def provider_outcome
        runner = ProviderRunner.new(provider_options)
        result = runner.run
        return result.except('judgment') unless result['status'] == 'completed'

        { 'judgment' => result['judgment'], 'usage' => result['usage'], 'binding' => provider_binding(runner, result) }
          .compact
      end

      # Only the model the CLI reports counts as observed; the effort is the one passed to the CLI.
      def provider_binding(runner, result)
        prompt = { 'source' => runner.instructions_source, 'sha256' => Judgment.prompt_sha256(runner.instructions) }
        binding(result['reviewer'], prompt, inputs(result['coverage']))
          .merge('model' => result['model'] || 'UNKNOWN', 'effort' => @settings['effort'] || 'UNKNOWN')
      end

      def provider_options
        @options.slice(:root, :base, :head, :criteria_ref, :description_file, :timeout_seconds, :repository)
                .merge(reviewer: @settings['reviewer'], model: @settings['model'], effort: @settings['effort'],
                       replacement_prompt_file: @settings['replacement_prompt_file']).compact
      end

      def parser
        OptionParser.new do |flags|
          flags.banner = 'Usage: shaka risk assess --root DIR --base SHA --head SHA --ref TRUSTED_SHA [options]'
          FLAGS.each { |key, flag| flags.on("--#{flag} VALUE") { |value| @options[key] = value } }
          flags.on('--ref SHA') { |value| @options[:criteria_ref] = value }
        end
      end
    end
  end
end
