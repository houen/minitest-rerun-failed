# frozen_string_literal: true

require "test_helper"

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
        output_path: "./test_output/#{FAIL_TEST_NAME}"
      )
    ]
  )
end

class MinitestRerunFailedTest < Minitest::Test
  # Suppress stdout / stderr output from secondary tests.
  # This is because we expect them to print a long stacktrace.
  # With it shown it would always look like tests failed.
  # Note that this also hides eg. Bundler::GemNotFound errors.
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
    fail_self
    File.read("./test_output/#{name}/.minitest_failed_tests.txt")
  end

  # Stub test to ensure tests can run.
  # This is here b/c #suppress_output also hides eg Bundler::GemNotFound errors.
  # This test will print and show such issues.
  def test_it_succeeds
    assert true
  end

  def test_that_it_has_a_version_number
    assert_not_nil ::MinitestRerunFailed::VERSION
  end

  def test_it_writes_failed_tests_to_stdout
    assert_not_empty fail_self_console_output
  end

  def test_it_writes_failed_tests_to_file
    assert_not_empty fail_self_file_output
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
