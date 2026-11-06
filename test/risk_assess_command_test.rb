# frozen_string_literal: true

require_relative 'review_prompt_file_test'
require 'shaka/risk_assessment/judgment'

# Builds a repository whose trusted commit holds the risk settings, then a candidate commit on top.
module RiskAssessFixture
  include ReviewPromptFileFixture

  JUDGMENT = { 'rating' => 'high', 'reasons' => ['Widens who can sign in'], 'unknowns' => [],
               'coverage_complete' => true, 'missing' => [] }.freeze

  private

  def with_risk_repository(settings)
    Dir.mktmpdir('shaka-risk') do |root|
      Dir.mktmpdir('shaka-risk-cli') do |bin|
        base = trusted_risk_commit(root, settings)
        File.write(File.join(root, '.agents/risk-prompt.md'), "Candidate risk instructions\n")
        File.write(File.join(root, 'app.rb'), "puts :changed\n")
        commit!(root, 'candidate change')
        yield root, base, git!(root, 'rev-parse', 'HEAD').strip, bin
      end
    end
  end

  def trusted_risk_commit(root, settings)
    git!(root, 'init')
    write_commands(root)
    File.write(File.join(root, '.agents/risk-prompt.md'), "Trusted risk instructions\n")
    File.write(File.join(root, '.agents/shaka/config.yml'), YAML.dump(seam({}).merge('risk_assessment' => settings)))
    commit!(root, 'trusted')
    git!(root, 'rev-parse', 'HEAD').strip
  end

  def write_commands(root)
    FileUtils.mkdir_p(File.join(root, '.agents/shaka/bin'))
    %w[setup validate test].each { write_executable(File.join(root, '.agents/shaka/bin'), it, "#!/bin/sh\n") }
  end

  def fake_classifier(bin, judgment)
    write_executable(bin, 'codex', <<~RUBY)
      #!/usr/bin/env ruby
      require 'json'
      File.write(ENV.fetch('REVIEW_TRACE'), JSON.generate({ args: ARGV, prompt: STDIN.read }))
      File.write(ARGV.fetch(ARGV.index('-o') + 1), #{JSON.generate(judgment).dump})
    RUBY
  end

  def assess(root, base, head, bin, *options)
    output, error, status = Open3.capture3(
      { 'PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'REVIEW_TRACE' => File.join(bin, 'trace.json'), **(@env || {}) },
      *COMMAND, 'risk', 'assess', '--root', root, '--base', base, '--head', head, '--ref', base, *options
    )
    [JSON.parse(output), status]
  rescue JSON::ParserError
    flunk "#{output}\n#{error}"
  end

  def trace(bin) = JSON.parse(File.read(File.join(bin, 'trace.json')))
end

class RiskAssessCommandTest < Minitest::Test
  include RiskAssessFixture

  def test_disabled_settings_make_no_classifier_call
    with_risk_repository({}) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT)
      result, status = assess(root, base, head, bin)
      assert_predicate status, :success?
      assert_equal 'disabled', result['status']
      refute_path_exists File.join(bin, 'trace.json')
    end
  end

  def test_provider_judgment_becomes_bound_evidence_with_a_shadow_ask
    with_risk_repository({ 'enabled' => true }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT)
      result, status = assess(root, base, head, bin)
      assert_predicate status, :success?, result.inspect
      assert_provider_evidence(result.fetch('evidence'), head, base)
      assert_equal %w[ask complete high], result['decision'].values_at('decision', 'state', 'rating')
      assert_includes trace(bin).fetch('prompt'), 'A small diff can be high risk'
    end
  end

  def assert_provider_evidence(evidence, head, base)
    judgment = Shaka::RiskAssessment::Judgment
    assert_equal [head, base, base], evidence.values_at('head', 'base', 'policy_ref')
    assert_equal({ 'kind' => 'provider', 'identity' => 'openai/codex', 'version' => 'UNKNOWN' }, evidence['runner'])
    assert_equal judgment.prompt_sha256(judgment.default_prompt), evidence.dig('prompt', 'sha256')
  end

  def test_replacement_prompt_comes_from_the_trusted_commit
    with_risk_repository({ 'enabled' => true,
                           'replacement_prompt_file' => '.agents/risk-prompt.md' }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT.merge('rating' => 'low'))
      result, = assess(root, base, head, bin)
      instructions = trace(bin).fetch('prompt').split('SUPPORTING SOURCE DATA').first
      assert_includes instructions, 'Trusted risk instructions'
      refute_includes instructions, 'Candidate risk instructions'
      assert_equal "#{base}:.agents/risk-prompt.md", result.dig('evidence', 'prompt', 'source')
      assert_equal 'auto_eligible', result.dig('decision', 'decision')
    end
  end

  # The trusted settings check refuses a named prompt file the settings commit lacks.
  def test_a_missing_replacement_prompt_fails_the_settings_check
    with_risk_repository({ 'enabled' => true,
                           'replacement_prompt_file' => '.agents/absent.md' }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT)
      output, status = Open3.capture2e({ 'PATH' => "#{bin}:#{ENV.fetch('PATH')}" }, *COMMAND, 'risk', 'assess',
                                       '--root', root, '--base', base, '--head', head, '--ref', base)
      refute_predicate status, :success?
      assert_includes output, 'risk_assessment.replacement_prompt_file'
      refute_path_exists File.join(bin, 'trace.json')
    end
  end

  def test_a_description_and_fenced_output_are_accepted
    with_risk_repository({ 'enabled' => true }) do |root, base, head, bin|
      write_executable(bin, 'codex', <<~RUBY)
        #!/usr/bin/env ruby
        File.write(ARGV.fetch(ARGV.index('-o') + 1), "```json\n" + #{JSON.generate(JUDGMENT).dump} + "\n```")
      RUBY
      description = File.join(bin, 'description.md')
      File.write(description, "Widen sign-in\n")
      result, = assess(root, base, head, bin, '--description-file', description)
      assert_equal %w[diff source_lookup description], result.dig('evidence', 'coverage', 'inputs')
    end
  end

  def test_a_judgment_with_unsupported_fields_is_not_evidence
    with_risk_repository({ 'enabled' => true }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT.merge('command' => 'bin/deploy'))
      result, status = assess(root, base, head, bin)
      refute_predicate status, :success?
      assert_equal 'not_completed', result['status']
      assert_includes result['reason'], 'unsupported fields: command'
      refute result.key?('evidence')
    end
  end

  # A classifier names no review profile or other requirement; only the rating fields count.
  def test_a_judgment_cannot_choose_a_profile
    with_risk_repository({ 'enabled' => true }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT.merge('profile' => 'skip-review'))
      result, status = assess(root, base, head, bin)
      refute_predicate status, :success?
      assert_includes result['reason'], 'unsupported fields: profile'
    end
  end

  def test_a_claimed_complete_judgment_that_lists_gaps_is_not_evidence
    with_risk_repository({ 'enabled' => true }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT.merge('missing' => ['description']))
      result, status = assess(root, base, head, bin)
      refute_predicate status, :success?
      assert_includes result['reason'], 'contradicts coverage.missing'
    end
  end
end

# The command's boundaries and what the evidence may claim it observed.
class RiskAssessBoundaryTest < Minitest::Test
  include RiskAssessFixture

  def test_requested_model_is_not_recorded_as_observed
    with_risk_repository({ 'enabled' => true, 'model' => 'chosen-model' }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT)
      result, = assess(root, base, head, bin)
      assert_equal %w[UNKNOWN low], result.fetch('evidence').values_at('model', 'effort')
      assert_includes trace(bin).fetch('args'), 'chosen-model'
    end
  end

  def test_a_candidate_git_on_path_never_runs
    with_risk_repository({}) do |root, base, _, bin|
      marker = File.join(bin, 'candidate-git-ran')
      FileUtils.mkdir_p(File.join(root, 'bin'))
      write_executable(File.join(root, 'bin'), 'git', "#!/bin/sh\ntouch #{marker}\nexit 1\n")
      commit!(root, 'candidate git')
      @env = { 'PATH' => "#{File.join(root, 'bin')}:#{bin}:#{ENV.fetch('PATH')}" }
      result, status = assess(root, base, git!(root, 'rev-parse', 'HEAD').strip, bin)
      assert_predicate status, :success?, result.inspect
      refute_path_exists marker
    end
  end

  def test_a_git_wrapper_with_a_candidate_interpreter_is_refused
    with_risk_repository({}) do |root, base, head, bin|
      wrapper = File.join(bin, 'wrapped')
      FileUtils.mkdir_p(wrapper)
      write_executable(wrapper, 'git', "#!#{File.join(root, 'app.rb')}\n")
      output, status = Open3.capture2e({ 'PATH' => "#{wrapper}:#{ENV.fetch('PATH')}" }, *COMMAND, 'risk', 'assess',
                                       '--root', root, '--base', base, '--head', head, '--ref', base)
      refute_predicate status, :success?
      assert_includes output, 'interpreter resolves inside candidate checkout'
    end
  end

  # A --root inside the checkout still resolves the checkout top for the PATH screen and settings.
  def test_a_subdirectory_root_rates_the_change
    with_risk_repository({ 'enabled' => true }) do |root, base, head, bin|
      fake_classifier(bin, JUDGMENT)
      result, status = assess(File.join(root, '.agents'), base, head, bin)
      assert_predicate status, :success?, result.inspect
      assert_equal 'high', result.dig('evidence', 'rating')
    end
  end
end

class RiskAssessmentSettingsTest < Minitest::Test
  def load(settings)
    data = { 'version' => 1, 'review' => { 'required' => 'none' }, 'merge' => { 'preference' => 'ask' },
             'risk_assessment' => settings }
    Shaka::RepositoryConfig.load(root: Dir.pwd, source: YAML.dump(data), available_commands: [])
  end

  def test_defaults_keep_classification_off_with_low_tolerance
    assert_equal({ 'enabled' => false, 'reviewer' => 'openai/codex', 'effort' => 'low', 'auto_max_risk' => 'low' },
                 load({}).risk_assessment)
  end

  def test_invalid_settings_are_refused
    { { 'auto_max_risk' => 'unknown' } => 'auto_max_risk', { 'command' => 'x' } => 'unknown risk_assessment key',
      { 'reviewer' => 'deepseek/openrouter' } => 'reviewer',
      { 'replacement_prompt_file' => '../outside' } => 'inside the repository',
      { 'enabled' => 'yes' } => 'enabled',
      { 'reviewer' => 'xai/grok' } => 'model is required' }.each do |settings, message|
      error = assert_raises(Shaka::Error) { load(settings) }
      assert_includes error.message, message
    end
  end
end
