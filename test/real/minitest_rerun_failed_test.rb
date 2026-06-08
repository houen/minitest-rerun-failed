# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

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
  ROOT = File.expand_path("../..", __dir__)
  LIB_DIR = File.join(ROOT, "lib")
  GEMFILE = File.join(ROOT, "Gemfile")
  CLI_PATH = File.join(ROOT, "bin/rerun_failed_tests")

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

  def subprocess_env(extra_env = {})
    {
      "BUNDLE_GEMFILE" => GEMFILE,
      "RUBYLIB" => [LIB_DIR, ENV["RUBYLIB"]].compact.join(File::PATH_SEPARATOR)
    }.merge(extra_env)
  end

  def capture_ruby(*args, chdir: nil, env: {})
    options = {}
    options[:chdir] = chdir if chdir

    Open3.capture3(subprocess_env(env), RbConfig.ruby, *args, **options)
  end

  # Stub test to ensure tests can run.
  # This is here b/c #suppress_output also hides eg Bundler::GemNotFound errors.
  # This test will print and show such issues.
  def test_it_succeeds
    assert true
  end

  def test_that_it_has_a_version_number
    refute ::MinitestRerunFailed::VERSION.nil?
  end

  def test_it_writes_failed_tests_to_stdout
    refute fail_self_console_output.nil?
  end

  def test_it_writes_failed_tests_to_file
    assert_match(%r{\Atest/real/minitest_rerun_failed_test.rb:[0-9]+\n\z}, fail_self_file_output)
  end

  def test_it_prints_failed_tests_with_seed
    assert_match(/Failed tests: [0-9]+ \(seed [0-9]+\)/, fail_self_console_output)
    assert_match(%r{test/real/minitest_rerun_failed_test.rb:[0-9]+\n}, fail_self_console_output)
  end

  def test_relevant_output_on_unexpected_errors
    assert_match(/Failed tests: [0-9]+ \(seed [0-9]+\)/, fail_self_console_output)
    assert_match(%r{test/real/minitest_rerun_failed_test.rb:[0-9]+\n}, fail_self_console_output)
  end

  def test_failed_tests_reporter_preserves_failed_exit_status
    Dir.mktmpdir do |dir|
      test_file = File.join(dir, "only_failed_reporter_test.rb")
      File.write(test_file, <<~RUBY)
        require "minitest/autorun"
        require "minitest_rerun_failed"

        Minitest::Reporters.use! [
          Minitest::Reporters::FailedTestsReporter.new(verbose: false, file_output: false)
        ]

        class OnlyFailedReporterTest < Minitest::Test
          def test_fail
            assert false
          end
        end
      RUBY

      _stdout, _stderr, status = capture_ruby(test_file)

      refute status.success?
    end
  end

  def test_failed_tests_reporter_honors_file_output_false
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "report")
      test_file = File.join(dir, "file_output_false_test.rb")
      File.write(test_file, <<~RUBY)
        require "minitest/autorun"
        require "minitest_rerun_failed"

        Minitest::Reporters.use! [
          Minitest::Reporters::FailedTestsReporter.new(
            output_path: #{output_path.dump},
            verbose: false,
            file_output: false
          )
        ]

        class FileOutputFalseTest < Minitest::Test
          def test_fail
            assert false
          end
        end
      RUBY

      capture_ruby(test_file)

      refute File.exist?(File.join(output_path, ".minitest_failed_tests.txt"))
    end
  end

  def test_rerun_failed_tests_uses_custom_report_dir_and_runs_non_rails_files
    Dir.mktmpdir do |dir|
      report_dir = File.join(dir, "report")
      test_dir = File.join(dir, "space path")
      FileUtils.mkdir_p([report_dir, test_dir])

      first_test = File.join(test_dir, "first_test.rb")
      second_test = File.join(test_dir, "second_test.rb")
      File.write(first_test, "puts \"FIRST_TEST_RAN\"\n")
      File.write(second_test, "puts \"SECOND_TEST_RAN\"\n")
      File.write(
        File.join(report_dir, ".minitest_failed_tests.txt"),
        "#{first_test}:123\n#{second_test}:456\n"
      )

      stdout, stderr, status = capture_ruby(
        CLI_PATH,
        chdir: dir,
        env: { "MINITEST_FAILED_TESTS_REPORT_DIR" => "report" }
      )

      assert status.success?, stderr
      assert_includes stdout, "FIRST_TEST_RAN"
      assert_includes stdout, "SECOND_TEST_RAN"
    end
  end

  def test_rerun_failed_tests_exits_with_child_status
    Dir.mktmpdir do |dir|
      report_dir = File.join(dir, "report")
      FileUtils.mkdir_p(report_dir)
      File.write(File.join(report_dir, ".minitest_failed_tests.txt"), "#{File.join(dir, "missing_test.rb")}\n")

      _stdout, _stderr, status = capture_ruby(
        CLI_PATH,
        chdir: dir,
        env: { "MINITEST_FAILED_TESTS_REPORT_DIR" => "report" }
      )

      refute status.success?
    end
  end
end
