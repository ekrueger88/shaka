# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../skills/shaka/lib/shaka/risk_assessment'

class RiskAssessmentTest < Minitest::Test
  def evidence(**changes)
    { 'schema_version' => 1, 'head' => 'a' * 40, 'base' => 'b' * 40, 'policy_ref' => 'c' * 40,
      'prompt' => { 'source' => 'built-in: risk prompt', 'sha256' => 'd' * 64 },
      'runner' => { 'kind' => 'provider', 'identity' => 'openai/codex', 'version' => 'UNKNOWN' },
      'model' => 'UNKNOWN', 'effort' => 'low',
      'coverage' => { 'inputs' => %w[diff description], 'complete' => true, 'missing' => [] },
      'rating' => 'high', 'reasons' => ['Changes who can sign in'], 'unknowns' => [] }
      .merge(changes.transform_keys(&:to_s))
  end

  def decide(value, tolerance: 'low') = Shaka::RiskAssessment.decide(value, tolerance:)

  # The same high-risk PR asks under the default tolerance and stays eligible where high risk is accepted.
  def test_tolerance_decides_without_changing_the_rating
    low = decide(evidence)
    high = decide(evidence, tolerance: 'high')
    assert_equal %w[ask high complete], low.values_at('decision', 'rating', 'state')
    assert_equal %w[auto_eligible high complete], high.values_at('decision', 'rating', 'state')
    assert_equal 'shadow', high['mode']
    assert_equal 'not evaluated', high['other_gates']
  end

  def test_rating_within_tolerance_is_eligible
    assert_equal 'auto_eligible', decide(evidence(rating: 'low'))['decision']
    assert_equal 'auto_eligible', decide(evidence(rating: 'medium'), tolerance: 'medium')['decision']
    assert_equal 'ask', decide(evidence(rating: 'medium'))['decision']
  end

  def malformed_cases
    { 'must be a JSON object' => [], 'unsupported fields: command' => evidence(command: 'rm -rf /'),
      'unsupported fields: profile' => evidence(profile: 'focused-checks'),
      'missing fields: reasons' => evidence.except('reasons'), 'schema_version must be' => evidence(schema_version: 2),
      'head must be a full lowercase commit SHA' => evidence(head: 'abc'),
      'prompt.sha256' => evidence(prompt: { 'source' => 'x', 'sha256' => 'short' }),
      'runner.kind' => evidence(runner: { 'kind' => 'script', 'identity' => 'x', 'version' => 'y' }),
      'coverage.inputs' => evidence(coverage: { 'inputs' => ['later_reviews'], 'complete' => true, 'missing' => [] }),
      'rating must be one of' => evidence(rating: 'critical'), 'reasons must not be empty' => evidence(reasons: []),
      'at most 500 characters' => evidence(reasons: ['x' * 501]) }
  end

  def test_malformed_evidence_is_refused_with_the_problem_named
    malformed_cases.each do |message, value|
      error = assert_raises(Shaka::Error, message) { decide(value) }
      assert_includes error.message, message
    end
  end

  def test_complete_coverage_must_agree_with_what_it_saw
    gaps = evidence(rating: 'low', coverage: { 'inputs' => ['diff'], 'complete' => true, 'missing' => ['description'] })
    assert_includes assert_raises(Shaka::Error) { decide(gaps) }.message, 'contradicts coverage.missing'
    blind = evidence(rating: 'low', coverage: { 'inputs' => ['checks'], 'complete' => true, 'missing' => [] })
    assert_includes assert_raises(Shaka::Error) { decide(blind) }.message, 'requires the diff'
  end

  def test_incomplete_coverage_and_unknown_rating_ask
    gap = { 'inputs' => ['diff'], 'complete' => false, 'missing' => ['description'] }
    incomplete = decide(evidence(rating: 'low', coverage: gap))
    assert_equal %w[incomplete ask], incomplete.values_at('state', 'decision')
    assert_includes incomplete['reason'], 'description'
    unknown = decide(evidence(rating: 'unknown'), tolerance: 'high')
    assert_equal %w[complete ask unknown], unknown.values_at('state', 'decision', 'rating')
  end

  def test_an_unknown_tolerance_raises
    assert_raises(Shaka::Error) { decide(evidence, tolerance: 'unknown') }
  end
end
