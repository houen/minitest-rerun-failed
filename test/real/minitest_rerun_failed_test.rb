# frozen_string_literal: true

require "test_helper"

def output_dir(fail_test_name)
  "#{__dir__}/../test_output/#{fail_test_name}"
end

# Which number test to run and fail
FAIL_TEST_NAME = ENV["FAIL_TEST_NAME"]

# Choose which reporter config to use for failing the test and generating output
case FAIL_TEST_NAME
when nil
  Minitest::Reporters.use!(
    [
      Minitest::Reporters::ProgressReporter.new,
      Minitest::Reporters::FailedTestsReporter.new(
        file_output: false
      )
    ]
  )
# when "test_it_prints_failed_tests_with_seed", "test_it_writes_failed_tests_to_file", "test_relevant_output_on_unexpected_errors"
else
  Minitest::Reporters.use!(
    [
      Minitest::Reporters::FailedTestsReporter.new(
        output_path: output_dir(FAIL_TEST_NAME)
      )
    ]
  )
end

class MinitestRerunFailedTest < Minitest::Test
  # Suppress stdout / stderr output from secondary tests
  # Source: https://gist.github.com/moertel/11091573
  def suppress_output
    original_stderr = $stderr.clone
    original_stdout = $stdout.clone
    $stderr.reopen(File.new("/dev/null", "w"))
    $stdout.reopen(File.new("/dev/null", "w"))
    yield
  ensure
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
  end

  def fail_self(fail_msg = nil)
    assert false, fail_msg if FAIL_TEST_NAME == name

    suppress_output do
      `bundle exec rake test FAIL_TEST_NAME=#{name} TEST=#{__FILE__} TESTOPTS="--name=#{name}"`
    end
  end

  alias fail_self_console_output fail_self

  def raise_self(fail_msg = nil)
    raise(fail_msg) if FAIL_TEST_NAME == name

    suppress_output do
      `bundle exec rake test FAIL_TEST_NAME=#{name} TEST=#{__FILE__} TESTOPTS="--name=#{name}"`
    end
  end

  def fail_self_file_output
    p output_dir(FAIL_TEST_NAME)
    fail_self
    File.read("#{output_dir(FAIL_TEST_NAME)}/.minitest_failed_tests.txt")
  end

  def test_that_it_has_a_version_number
    refute_nil ::MinitestRerunFailed::VERSION
  end

  def test_it_writes_failed_tests_to_stdout
    refute_empty fail_self_console_output
  end

  def test_it_writes_failed_tests_to_file
    refute_empty fail_self_file_output
  end

  def test_it_prints_failed_tests_with_seed
    assert_match(/Failed tests: [0-9]+ \(seed [0-9]+\)/, fail_self_console_output)
    assert_match(%r{test/real/minitest_rerun_failed_test.rb:[0-9]+\n}, fail_self_console_output)
  end

  def test_relevant_output_on_unexpected_errors
    assert_match(/Failed tests: [0-9]+ \(seed [0-9]+\)/, fail_self_console_output)
    assert_match(%r{test/real/minitest_rerun_failed_test.rb:[0-9]+\n}, fail_self_console_output)
  end
end
