# frozen_string_literal: true

require_relative '../local_review/runner'
require_relative 'judgment'

module Shaka
  module RiskAssessment
    # Rates one change through a provider CLI, reusing the local review runner's restricted process,
    # pinned-commit checks, and trusted prompt reader.
    class ProviderRunner < LocalReviewRunner
      SUPPORTED = %w[openai/codex anthropic/claude xai/grok].freeze

      # The instructions this run sends, for the evidence's prompt digest and source.
      attr_reader :instructions, :instructions_source

      private

      def validate_reviewer!
        raise Shaka::Error, '--ref must be a full trusted default-branch commit SHA' unless @options[:criteria_ref]

        normalize_reviewer!
        raise Shaka::Error, "risk_assessment.reviewer must be one of #{SUPPORTED.join(', ')}" unless
          SUPPORTED.include?(reviewer)
        raise Shaka::Error, 'xai/grok requires risk_assessment.model' if reviewer == 'xai/grok' && !@options[:model]

        load_instructions
      end

      def normalize_reviewer!
        @options[:reviewer] = ReviewerSelection.parse(@options.fetch(:reviewer)).values.map(&:downcase).join('/')
      end

      def load_instructions
        path = @options[:replacement_prompt_file]
        @instructions_source = path ? "#{settings_ref}:#{path}" : 'built-in: risk-assessment-prompt.md'
        @instructions = if path
                          configured_prompt(path,
                                            'risk_assessment.replacement_prompt_file')
                        else
                          Judgment.default_prompt
                        end
      end

      # Settings, prompt, and policy_ref all come from --ref; a settings preview does not apply here.
      def settings_ref = @options[:criteria_ref]

      def review_prompt = PromptSection.join(prompt_sections(SecureRandom.hex(16)))

      def prompt_sections(marker)
        [PromptSection.new(instructions_source, "#{instructions}\n"),
         PromptSection.new('built-in: risk judgment contract', "#{Judgment::CONTRACT}\n"),
         *source_context(marker), diff_section(marker)]
      end

      def validate_report(path)
        judgment = Judgment.read(File.read(path, encoding: 'UTF-8'))
        File.unlink(path)
        { 'status' => 'completed', 'head' => head, 'reviewer' => reviewer, 'judgment' => judgment,
          'model' => @options[:observed_model], 'usage' => @options[:usage], 'coverage' => coverage }.compact
      rescue Shaka::Error, SystemCallError => e
        incomplete(e.message, path)
      end
    end
  end
end
