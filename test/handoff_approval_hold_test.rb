# frozen_string_literal: true

require_relative 'handoff_helper'

class HandoffApprovalHoldTest < Minitest::Test
  include HandoffHarness

  HELD = { 'name' => 'deploy', 'state' => 'WAITING', 'bucket' => 'pending',
           'link' => 'https://github.com/owner/repo/actions/runs/7' }.freeze

  # A check waiting on a deployment approval never finishes, so no monitor that waits for checks will fire.
  def test_a_wake_source_does_not_cover_a_check_held_for_approval
    result = handoff(labels: [], woken_by: 'host PR monitor', checks: [HELD])

    assert_includes result['status'], 'blocked (approval hold): deploy'
    owed = result['owed'].join("\n")
    assert_includes owed, 'deploy waits on a manual approval'
    assert_includes owed, HELD['link']
  end

  def test_a_labeled_pr_with_a_held_check_names_the_approval_without_owing_it
    result = handoff(labels: ['awaiting-resume'], checks: [HELD])

    assert_empty result['owed']
    assert(result['notes'].any? { |note| note.include?('deploy waits on a manual approval') })
  end
end
