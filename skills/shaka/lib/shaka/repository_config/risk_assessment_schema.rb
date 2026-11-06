# frozen_string_literal: true

require_relative 'validation'
require_relative 'post_implementation_schema'
require_relative '../defaults'
require_relative '../risk_assessment'

module Shaka
  class RepositoryConfig
    # Opt-in risk classification by a provider that trusted settings name; nothing here lets a
    # classifier choose what runs.
    class RiskAssessmentSchema
      include Validation

      KEY = 'risk_assessment'
      KEYS = %w[enabled reviewer model effort replacement_prompt_file auto_max_risk].freeze
      DEFAULTS = Defaults.fetch(KEY)
      EFFORTS = PostImplementationSchema::EFFORTS

      def self.effective(settings) = DEFAULTS.merge(settings || {})

      def initialize(settings) = @settings = settings

      def validate
        mapping!(@settings, KEY)
        keys!(@settings, [], KEYS, KEY)
        enum!(@settings['enabled'], [true, false], "#{KEY}.enabled must be true or false") if @settings.key?('enabled')
        validate_reviewer
        enum!(@settings.fetch('auto_max_risk', DEFAULTS.fetch('auto_max_risk')), RiskAssessment::RATINGS,
              "#{KEY}.auto_max_risk must be one of #{RiskAssessment::RATINGS.join(', ')}")
        prompt_paths!(@settings, %w[replacement_prompt_file], KEY)
      end

      private

      def validate_reviewer
        reviewer = PostImplementationSchema.reviewer(@settings.fetch('reviewer', DEFAULTS.fetch('reviewer')))
        raise Error, "#{KEY}.reviewer must be one of #{EFFORTS.keys.join(', ')}" unless EFFORTS.key?(reviewer)

        ReviewSchema.model_name!(@settings['model'], "#{KEY}.model") if @settings.key?('model')
        validate_effort(reviewer) if @settings.key?('effort')
      end

      def validate_effort(reviewer)
        return if EFFORTS.fetch(reviewer).include?(@settings['effort'])

        raise Error, "#{KEY}.effort must be #{EFFORTS.fetch(reviewer).join(', ')} for #{reviewer}"
      end
    end
  end
end
