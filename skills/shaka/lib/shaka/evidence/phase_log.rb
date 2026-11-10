# frozen_string_literal: true

require 'json'
require 'tmpdir'

module Shaka
  module Evidence
    # Lets a fixed command report how long each of its own phases took, so a slow validation run
    # shows which part was slow. `evidence run` names an empty file in SHAKA_PHASE_LOG, and the
    # command may append one JSON line per phase, such as {"phase":"tests","duration_ms":250000}.
    # The command is candidate code and the phases are published, so only a short lowercase name and a
    # whole number of milliseconds are kept, for at most eight names; any other line is skipped.
    module PhaseLog
      VARIABLE = 'SHAKA_PHASE_LOG'
      NAME = /\A[a-z][a-z0-9_-]{0,23}\z/
      MAX_PHASES = 8
      MAX_BYTES = 64 * 1024
      # Thirty days; a larger value is not a measurement and could overflow the duration renderer.
      MAX_MS = 30 * 24 * 3_600_000

      module_function

      # Yields the file path to hand the command and returns the block's value with the phases read back.
      def with_file
        Dir.mktmpdir('shaka-phases') do |directory|
          path = File.join(directory, 'phases.jsonl')
          File.write(path, '', perm: 0o600)
          value = yield path
          [value, read(path)]
        end
      end

      # Opens without waiting and reads only a regular file, so a command that swaps the file for a pipe,
      # a device, or a link cannot stall the helper or point it elsewhere.
      OPEN_FLAGS = %i[NONBLOCK NOFOLLOW].sum(File::RDONLY) { |flag| File.const_defined?(flag) ? File.const_get(flag) : 0 }

      def read(path)
        text = File.open(path, OPEN_FLAGS, binmode: true) { |io| io.stat.file? ? io.read(MAX_BYTES) : nil }
        text = (+text.to_s).force_encoding(Encoding::UTF_8)
        text.valid_encoding? ? sanitize(text.each_line.filter_map { |line| parse(line) }) : {}
      rescue SystemCallError, IOError
        {}
      end

      def parse(line)
        record = JSON.parse(line)
        [record['phase'], record['duration_ms']] if record.is_a?(Hash)
      rescue JSON::ParserError, EncodingError
        nil
      end

      # Phase names with their total milliseconds, in first-reported order: {"tests" => 250000}. A
      # phase reported twice is summed. A result file or description body is editable, so every
      # reader passes its phases through here again.
      def sanitize(phases)
        pairs = phases.is_a?(Hash) ? phases.to_a : Array(phases)
        pairs.each_with_object({}) do |(name, duration), totals|
          next unless shaped?(name, duration) && (totals.key?(name) || totals.size < MAX_PHASES)

          sum = totals.fetch(name, 0) + duration
          totals[name] = sum if sum <= MAX_MS
        end
      end

      def shaped?(name, duration)
        name.is_a?(String) && NAME.match?(name) && duration.is_a?(Integer) && duration.between?(0, MAX_MS)
      end

      # Adds several runs' phases together. The phase cap applies to each run, not to the sum, so a name
      # only a later run reported is kept.
      def combine(list)
        list.each_with_object({}) do |phases, totals|
          sanitize(phases).each { |name, value| totals[name] = totals.fetch(name, 0) + value }
        end
      end

      # "tests 4m 10s · rubocop 1m 2s", from phases already passed through `sanitize` or `combine`.
      def summary(phases, duration)
        phases.map { |name, milliseconds| "#{name} #{duration.call(milliseconds)}" }.join(' · ')
      end
    end
  end
end
