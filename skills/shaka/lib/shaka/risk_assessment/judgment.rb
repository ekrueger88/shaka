# frozen_string_literal: true

require 'digest'
require 'json'
require_relative '../risk_assessment'

module Shaka
  module RiskAssessment
    # What a classifier may decide, and the evidence Shaka builds around it. The classifier
    # returns only its judgment; Shaka supplies the binding, so a classifier cannot claim it
    # assessed another commit, prompt, or runner.
    module Judgment
      DEFAULT_PROMPT = File.expand_path('../../../config/risk-assessment-prompt.md', __dir__)
      FIELDS = %w[rating reasons unknowns coverage_complete missing].freeze
      MAX_BYTES = 100_000

      # Packaged apart from the replaceable prompt, so a replacement cannot change what Ruby parses.
      CONTRACT = File.read(File.expand_path('../../../config/risk-assessment-contract.md', __dir__),
                           encoding: 'UTF-8')
                     .gsub('{{ratings}}', (RATINGS + [UNKNOWN]).join(', '))
                     .gsub('{{max_items}}', MAX_ITEMS.to_s).freeze

      module_function

      def default_prompt = File.read(DEFAULT_PROMPT, encoding: 'UTF-8')

      # The digest covers the rating instructions and the fixed contract, so editing either changes it.
      # Shaka's built-in source-context wording is not part of it.
      def prompt_sha256(instructions) = Digest::SHA256.hexdigest("#{instructions}\n#{CONTRACT}")

      def read(text)
        raise Error, 'Risk judgment exceeds 100 KB' if text.bytesize > MAX_BYTES

        judgment = JSON.parse(unfenced(text))
        raise Error, 'Risk judgment must be a JSON object' unless judgment.is_a?(Hash)

        extra = judgment.keys - FIELDS
        raise Error, "Risk judgment has unsupported fields: #{extra.sort.join(', ')}" if extra.any?

        judgment
      rescue JSON::ParserError
        raise Error, 'Risk judgment is not valid JSON'
      end

      # Some CLIs wrap a JSON-only answer in a Markdown fence anyway.
      def unfenced(text) = text.strip.delete_prefix('```json').delete_prefix('```').delete_suffix('```')

      # binding holds head, base, policy_ref, prompt, runner, model, effort, and the inputs supplied.
      def evidence(judgment, binding)
        coverage = { 'inputs' => binding.fetch('inputs'), 'complete' => judgment['coverage_complete'],
                     'missing' => judgment['missing'] }
        RiskAssessment.parse({ 'schema_version' => SCHEMA_VERSION, 'coverage' => coverage }
              .merge(binding.except('inputs'))
              .merge(judgment.slice('rating', 'reasons', 'unknowns')))
      end
    end
  end
end
