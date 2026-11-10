# frozen_string_literal: true

require_relative '../call_log'
require_relative 'phase_log'

module Shaka
  module Evidence
    # Gives a fixed command the environment it runs with, naming the file it may report phases into,
    # and adds those phases to the timing the block returns beside the command's outcome.
    module TimedCheck
      module_function

      def run(path)
        (outcome, timing), phases = PhaseLog.with_file do |log|
          yield({ 'PATH' => path, PhaseLog::VARIABLE => log })
        end
        [outcome, CallLog.phases(phases) ? timing.merge('phases' => phases) : timing]
      end
    end
  end
end
