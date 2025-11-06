require "test/unit"
require "core_assertions"

module Test::Unit::CoreAssertions
  def assert_linear_performance(seq, rehearsal: nil, pre: ->(n) {n})
    pend "No PERFORMANCE_CLOCK found" unless defined?(PERFORMANCE_CLOCK)

    # Timeout testing generally doesn't work when RJIT compilation happens.
    rjit_enabled = defined?(RubyVM::RJIT) && RubyVM::RJIT.enabled?
    measure = proc do |arg, message|
      st = Process.clock_gettime(PERFORMANCE_CLOCK)
      puts "st: #{st}"
      yield(*arg)
      value = Process.clock_gettime(PERFORMANCE_CLOCK)
      puts "after yield"
      puts "value: #{value}"
      t = value - st
      puts "t: #{t}"
      assert_operator 0, :<=, t, message unless rjit_enabled
      t
    end

    first = seq.first
    *arg = pre.call(first)
    times = (0..(rehearsal || (2 * first))).map do
      value = measure[arg, "rehearsal"]
      puts "value: #{value}"
      value.nonzero?
    end

    times.compact!

    if times.empty?
      msg = <<~MSG
        Rehearsal time was too short to determine linear performance threshold.
        Make sure the target code takes more than 1 ms to execute.
      MSG
      fail Test::Unit::AssertionFailedError, msg
    end

    tmin, tmax = times.minmax

    # safe_factor * tmax * rehearsal_time_variance_factor(equals to 1 when variance is small)
    tbase = 10 * tmax * [(tmax / tmin) ** 2 / 4, 1].max
    info = "(tmin: #{tmin}, tmax: #{tmax}, tbase: #{tbase})"

    seq.each do |i|
      next if i == first
      t = tbase * i.fdiv(first)
      *arg = pre.call(i)
      message = "[#{i}]: in #{t}s #{info}"
      Timeout.timeout(t, Timeout::Error, message) do
        measure[arg, message]
      end
    end
  end
end

Test::Unit::TestCase.include Test::Unit::CoreAssertions
