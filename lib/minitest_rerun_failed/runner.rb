# frozen_string_literal: true

require "English"

module MinitestRerunFailed
  class Runner
    DEFAULT_FILENAME = ".minitest_failed_tests.txt"
    DEFAULT_REPORT_DIR = "./"

    def initialize(
      report_dir: ENV.fetch("MINITEST_FAILED_TESTS_REPORT_DIR", DEFAULT_REPORT_DIR),
      filename: DEFAULT_FILENAME,
      io: $stdout,
      command_runner: nil
    )
      @report_dir = report_dir
      @filename = filename
      @io = io
      @command_runner = command_runner
    end

    def call
      return report_missing_file unless File.exist?(filepath)
      return report_empty_file if File.empty?(filepath)

      failed_tests = read_failed_tests
      return report_empty_file if failed_tests.empty?

      run_commands(commands_for(failed_tests))
    end

    def commands_for(failed_tests)
      if rails_installed?
        [
          ["bundle", "exec", "rails", "test", *failed_tests]
        ]
      else
        ruby_test_files(failed_tests).map do |test_file|
          ["bundle", "exec", "ruby", test_file]
        end
      end
    end

    private

    attr_reader :report_dir, :filename, :io, :command_runner

    def filepath
      File.join(report_dir, filename)
    end

    def read_failed_tests
      File.readlines(filepath, chomp: true).map(&:strip).reject(&:empty?)
    end

    def ruby_test_files(failed_tests)
      failed_tests.map { |test_file| test_file.sub(/:[0-9]+\z/, "") }.uniq
    end

    def rails_installed?
      Gem.loaded_specs.key?("rails")
    end

    def run_commands(commands)
      commands.each do |command|
        exit_status = run_command(command)
        return exit_status unless exit_status.zero?
      end

      0
    end

    def run_command(command)
      return command_runner.call(command) if command_runner

      system(*command)
      $CHILD_STATUS&.exitstatus || 1
    end

    def report_missing_file
      io.puts "No #{filename} found"
      0
    end

    def report_empty_file
      io.puts "No failed tests in #{filename}"
      0
    end
  end
end
