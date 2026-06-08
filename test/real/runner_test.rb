# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "stringio"
require "tmpdir"

require "minitest_rerun_failed/runner"

class RunnerTest < Minitest::Test
  def setup
    @io = StringIO.new
  end

  def test_reports_missing_file
    Dir.mktmpdir do |dir|
      runner = MinitestRerunFailed::Runner.new(report_dir: dir, io: @io)

      assert_equal 0, runner.call
      assert_equal "No .minitest_failed_tests.txt found\n", @io.string
    end
  end

  def test_reports_empty_file
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".minitest_failed_tests.txt"), "")
      runner = MinitestRerunFailed::Runner.new(report_dir: dir, io: @io)

      assert_equal 0, runner.call
      assert_equal "No failed tests in .minitest_failed_tests.txt\n", @io.string
    end
  end

  def test_plain_ruby_commands_strip_line_numbers_and_deduplicate_files
    runner = MinitestRerunFailed::Runner.new(io: @io)

    commands = runner.commands_for(
      [
        "test/example_test.rb:12",
        "test/example_test.rb:18",
        "test/another_test.rb"
      ]
    )

    assert_equal(
      [
        ["bundle", "exec", "ruby", "test/example_test.rb"],
        ["bundle", "exec", "ruby", "test/another_test.rb"]
      ],
      commands
    )
  end

  def test_runs_commands_until_first_failure
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".minitest_failed_tests.txt"), "test/first_test.rb\ntest/second_test.rb\n")
      commands = []
      runner = MinitestRerunFailed::Runner.new(
        report_dir: dir,
        io: @io,
        command_runner: lambda do |command|
          commands << command
          1
        end
      )

      assert_equal 1, runner.call
      assert_equal [["bundle", "exec", "ruby", "test/first_test.rb"]], commands
    end
  end

  def test_uses_custom_report_dir
    Dir.mktmpdir do |dir|
      report_dir = File.join(dir, "report")
      FileUtils.mkdir_p(report_dir)
      File.write(File.join(report_dir, ".minitest_failed_tests.txt"), "test/example_test.rb:12\n")
      commands = []
      runner = MinitestRerunFailed::Runner.new(
        report_dir: report_dir,
        io: @io,
        command_runner: lambda do |command|
          commands << command
          0
        end
      )

      assert_equal 0, runner.call
      assert_equal [["bundle", "exec", "ruby", "test/example_test.rb"]], commands
    end
  end
end
