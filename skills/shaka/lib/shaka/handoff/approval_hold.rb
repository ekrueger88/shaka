# frozen_string_literal: true

require_relative '../status'

module Shaka
  # Names required checks held for a deployment approval. Such a check finishes only after a person
  # approves it, so a monitor that waits for checks never fires and cannot stand in for a label.
  module HandoffApprovalHold
    private

    def held_fact(checks)
      held = checks.select { |check| check['blocked'] == Status::APPROVAL_HOLD }
      return if held.empty?

      held.each do |check|
        approve = "#{check['name']} waits on a manual approval; approve it at #{check['link'] || 'its workflow run'}"
        next @notes << "#{approve}." unless @woken_by

        @owed << "#{approve}, or set awaiting-resume and run handoff without --woken-by: " \
                 "#{@woken_by} will not wake for it."
      end
      "blocked (#{Status::APPROVAL_HOLD}): #{held.map { |check| check['name'] }.join(', ')}"
    end
  end
end
