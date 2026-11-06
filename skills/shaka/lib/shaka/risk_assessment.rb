# frozen_string_literal: true

require_relative 'error'

module Shaka
  # One PR's risk assessment, kept as evidence that names exactly what was assessed and by what.
  # Nothing here runs a model or changes a merge: callers read the decision in shadow.
  #
  # The rating measures the change's own impact and recovery. Verification adequacy, the human
  # review floors that changed paths set, and the repository's tolerance stay separate, so raising
  # tolerance never needs a lower rating and a high rating alone never blocks a merge.
  module RiskAssessment
    SCHEMA_VERSION = 1
    # Ordered from least to most risk; unknown is never inside any tolerance.
    RATINGS = %w[low medium high].freeze
    UNKNOWN = 'unknown'
    RUNNER_KINDS = %w[provider].freeze
    INPUTS = %w[diff description source_lookup checks].freeze
    SHA = /\A[0-9a-f]{40}\z/
    DIGEST = /\A[0-9a-f]{64}\z/
    MAX_TEXT = 500
    MAX_ITEMS = 20
    FIELDS = %w[schema_version head base policy_ref prompt runner model effort coverage rating reasons
                unknowns].freeze

    module_function

    # Returns the evidence when every field is well formed, or raises Error naming the first problem.
    # Unknown keys are refused, so an assessment cannot smuggle instructions such as a command.
    def parse(evidence)
      raise Error, 'Risk assessment must be a JSON object' unless evidence.is_a?(Hash)

      extra = evidence.keys - FIELDS
      raise Error, "Risk assessment has unsupported fields: #{extra.sort.join(', ')}" if extra.any?

      missing = FIELDS - evidence.keys
      raise Error, "Risk assessment is missing fields: #{missing.join(', ')}" if missing.any?

      Fields.check(evidence)
      evidence
    end

    # What the rating alone would decide for evidence just built by parse. Incomplete coverage, an
    # unknown rating, or a rating above tolerance is Ask.
    def decide(evidence, tolerance:)
      validate_tolerance!(tolerance)
      parse(evidence)
      return ask('incomplete', "Assessment #{gaps(evidence['coverage'])}", evidence) unless
        evidence.dig('coverage', 'complete')

      rating = evidence['rating']
      return ask('complete', 'Rating is unknown', evidence) if rating == UNKNOWN
      return ask('complete', "Rating #{rating} exceeds tolerance #{tolerance}", evidence) if above?(rating, tolerance)

      result('complete', 'auto_eligible', "Rating #{rating} is within tolerance #{tolerance}", evidence)
    end

    def gaps(coverage)
      coverage['missing'].empty? ? 'coverage incomplete' : "missing #{coverage['missing'].join(', ')}"
    end

    def above?(rating, tolerance) = RATINGS.index(rating) > RATINGS.index(tolerance)

    def validate_tolerance!(tolerance)
      return if RATINGS.include?(tolerance)

      raise Error, "Risk tolerance must be one of #{RATINGS.join(', ')}"
    end

    def ask(state, reason, evidence) = result(state, 'ask', reason, evidence)

    # Shadow results say what the risk gate alone would decide; the other merge gates still apply.
    def result(state, decision, reason, evidence)
      { 'mode' => 'shadow', 'state' => state, 'decision' => decision, 'reason' => reason,
        'rating' => evidence.fetch('rating'), 'other_gates' => 'not evaluated' }
    end

    # Field-level checks, kept apart so the top-level rules above read in one place.
    module Fields
      module_function

      # Each field's check takes the value and the field name.
      CHECKS = { 'schema_version' => :version!, 'head' => :sha!, 'base' => :sha!, 'policy_ref' => :sha!,
                 'prompt' => :prompt!, 'runner' => :runner!, 'model' => :text!, 'effort' => :text!,
                 'coverage' => :coverage!, 'rating' => :rating!, 'reasons' => :reasons!, 'unknowns' => :list! }.freeze

      def check(evidence) = evidence.each { |name, value| public_send(CHECKS.fetch(name), value, name) }

      def version!(value, _name)
        raise Error, "schema_version must be #{SCHEMA_VERSION}" unless value == SCHEMA_VERSION
      end

      def sha!(value, name)
        raise Error, "#{name} must be a full lowercase commit SHA" unless value.is_a?(String) && value.match?(SHA)
      end

      def prompt!(value, _name)
        object!(value, 'prompt', %w[source sha256])
        text!(value['source'], 'prompt.source')
        raise Error, 'prompt.sha256 must be a SHA-256 hex digest' unless value['sha256'].to_s.match?(DIGEST)
      end

      def runner!(value, _name)
        object!(value, 'runner', %w[kind identity version])
        raise Error, "runner.kind must be one of #{RUNNER_KINDS.join(', ')}" unless RUNNER_KINDS.include?(value['kind'])

        text!(value['identity'], 'runner.identity')
        text!(value['version'], 'runner.version')
      end

      def coverage!(value, _name)
        object!(value, 'coverage', %w[inputs complete missing])
        inputs!(value['inputs'])
        raise Error, 'coverage.complete must be true or false' unless [true, false].include?(value['complete'])

        list!(value['missing'], 'coverage.missing')
        complete!(value) if value['complete']
      end

      # Completeness is the classifier's own claim, so it must at least agree with what it says it saw.
      def complete!(value)
        raise Error, 'coverage.complete contradicts coverage.missing' if value['missing'].any?
        raise Error, 'coverage.complete requires the diff among coverage.inputs' unless value['inputs'].include?('diff')
      end

      def inputs!(inputs)
        return if inputs.is_a?(Array) && !inputs.empty? && inputs.all? { INPUTS.include?(it) } && inputs.uniq == inputs

        raise Error, "coverage.inputs must list some of #{INPUTS.join(', ')}"
      end

      def rating!(value, _name)
        allowed = RATINGS + [UNKNOWN]
        raise Error, "rating must be one of #{allowed.join(', ')}" unless allowed.include?(value)
      end

      def object!(value, name, keys)
        raise Error, "#{name} must be an object with #{keys.join(', ')}" unless value.is_a?(Hash) &&
                                                                                value.keys.sort == keys.sort
      end

      def text!(value, name)
        return if value.is_a?(String) && !value.strip.empty? && value.length <= MAX_TEXT

        raise Error, "#{name} must be nonblank text of at most #{MAX_TEXT} characters"
      end

      def reasons!(value, name)
        raise Error, "#{name} must not be empty" if value.is_a?(Array) && value.empty?

        list!(value, name)
      end

      def list!(value, name)
        raise Error, "#{name} must be a list of at most #{MAX_ITEMS} entries" unless value.is_a?(Array) &&
                                                                                     value.size <= MAX_ITEMS

        value.each { text!(it, name) }
      end
    end
  end
end
