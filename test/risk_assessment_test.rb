# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../skills/shaka/lib/shaka/risk_assessment'

class RiskAssessmentTest < Minitest::Test
  HEAD = 'a' * 40
  BASE = 'b' * 40
  POLICY = 'c' * 40
  PROMPT = 'd' * 64

  def evidence(**changes)
    { 'schema_version' => 1, 'head' => HEAD, 'base' => BASE, 'policy_ref' => POLICY,
      'prompt' => { 'source' => 'built-in: risk prompt', 'sha256' => PROMPT },
      'runner' => { 'kind' => 'provider', 'identity' => 'openai/codex', 'version' => 'UNKNOWN' },
      'model' => 'UNKNOWN', 'effort' => 'low',
      'coverage' => { 'inputs' => %w[diff description], 'complete' => true, 'missing' => [] },
      'rating' => 'high', 'reasons' => ['Changes who can sign in'], 'unknowns' => [] }
      .merge(changes.transform_keys(&:to_s))
  end

  def expected(**changes)
    { 'head' => HEAD, 'base' => BASE, 'policy_ref' => POLICY, 'prompt_sha256' => PROMPT,
      'runner' => 'provider:openai/codex' }.merge(changes.transform_keys(&:to_s))
  end

  def decide(value, tolerance: 'low', **changes)
    Shaka::RiskAssessment.decide(value, expected: expected(**changes), tolerance:)
  end

  # The same high-risk PR asks under the default tolerance and stays eligible where high risk is accepted.
  def test_tolerance_decides_without_changing_the_rating
    low = decide(evidence)
    high = decide(evidence, tolerance: 'high')
    assert_equal %w[ask high current], low.values_at('decision', 'rating', 'state')
    assert_equal %w[auto_eligible high current], high.values_at('decision', 'rating', 'state')
    assert_equal 'shadow', high['mode']
    assert_equal 'not evaluated', high['other_gates']
  end

  def test_rating_within_tolerance_is_eligible
    assert_equal 'auto_eligible', decide(evidence(rating: 'low'))['decision']
    assert_equal 'auto_eligible', decide(evidence(rating: 'medium'), tolerance: 'medium')['decision']
    assert_equal 'ask', decide(evidence(rating: 'medium'))['decision']
  end

  def test_missing_evidence_asks
    assert_equal %w[missing ask], decide(nil).values_at('state', 'decision')
  end

  def malformed_cases
    { 'must be a JSON object' => [], 'unsupported fields: command' => evidence(command: 'rm -rf /'),
      'missing fields: reasons' => evidence.except('reasons'), 'schema_version must be' => evidence(schema_version: 2),
      'head must be a full lowercase commit SHA' => evidence(head: 'abc'),
      'prompt.sha256' => evidence(prompt: { 'source' => 'x', 'sha256' => 'short' }),
      'runner.kind' => evidence(runner: { 'kind' => 'shell', 'identity' => 'x', 'version' => 'y' }),
      'coverage.inputs' => evidence(coverage: { 'inputs' => ['later_reviews'], 'complete' => true, 'missing' => [] }),
      'rating must be one of' => evidence(rating: 'critical'), 'reasons must not be empty' => evidence(reasons: []),
      'unsupported fields: profile' => evidence(profile: 'focused-checks'),
      'at most 500 characters' => evidence(reasons: ['x' * 501]) }
  end

  def test_malformed_evidence_asks_and_names_the_problem
    malformed_cases.each do |message, value|
      result = decide(value)
      assert_equal %w[malformed ask], result.values_at('state', 'decision'), message
      assert_includes result['reason'], message
    end
  end

  def test_complete_coverage_that_lists_gaps_is_malformed
    coverage = { 'inputs' => ['diff'], 'complete' => true, 'missing' => ['description'] }
    result = decide(evidence(rating: 'low', coverage:))
    assert_equal %w[malformed ask], result.values_at('state', 'decision')
    blind = decide(evidence(rating: 'low', coverage: { 'inputs' => ['checks'], 'complete' => true, 'missing' => [] }))
    assert_equal 'malformed', blind['state']
    assert_includes blind['reason'], 'requires the diff'
  end

  def test_any_binding_change_makes_evidence_stale
    { head: 'e' * 40, base: 'f' * 40, policy_ref: '0' * 40, prompt_sha256: '1' * 64,
      runner: 'provider:anthropic/claude' }.each do |field, value|
      result = decide(evidence(rating: 'low'), **{ field => value })
      assert_equal %w[stale ask], result.values_at('state', 'decision'), field
      assert_includes result['reason'], field.to_s
    end
  end

  def test_pinned_model_and_effort_bind_only_when_expected
    assert_equal 'auto_eligible', decide(evidence(rating: 'low'))['decision']
    assert_equal 'stale', decide(evidence(rating: 'low'), model: 'gpt-x')['state']
    assert_equal 'stale', decide(evidence(rating: 'low'), effort: 'high')['state']
    assert_equal 'current', decide(evidence(rating: 'low'), effort: 'low')['state']
  end

  def test_incomplete_coverage_and_unknown_rating_ask
    gap = { 'inputs' => ['diff'], 'complete' => false, 'missing' => ['description'] }
    incomplete = decide(evidence(rating: 'low', coverage: gap))
    assert_equal %w[incomplete ask], incomplete.values_at('state', 'decision')
    assert_includes incomplete['reason'], 'description'
    unknown = decide(evidence(rating: 'unknown'), tolerance: 'high')
    assert_equal %w[current ask unknown], unknown.values_at('state', 'decision', 'rating')
  end

  def test_programming_errors_raise
    assert_raises(Shaka::Error) { Shaka::RiskAssessment.decide(evidence, expected: {}, tolerance: 'low') }
    assert_raises(Shaka::Error) { decide(evidence, tolerance: 'unknown') }
  end
end
