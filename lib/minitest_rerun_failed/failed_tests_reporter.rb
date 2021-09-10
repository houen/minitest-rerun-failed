# frozen_string_literal: true

module Minitest
  module Reporters
    # Source: https://www.houen.net/2021/08/23/minitest-rerun-failed-tests/
    # License: MIT
    #
    # Outputs failed tests to screen and / or file
    # Allows to rerun only failed tests with minitest if added to Minitest::Reporters.use!
    #
    # Example:
    #   In test_helper.rb or similar:
    #   Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new, Minitest::Reporters::FailedTestsReporter.new(verbose: true, include_line_numbers: true)]
    #
    #   Now after a failed test run, rerun failed tests only with: `bundle exec rails test $(cat .minitest_failed_tests.txt)`
    #
    class FailedTestsReporter < Minitest::Reporters::BaseReporter
      def initialize(options = {})
        super(options)
        @options = options

        # Include line numbers? (failed_test.rb:42 or just failed_test.rb)
        @include_line_numbers = options.fetch(:include_line_numbers, true)
        # Output to console?
        @verbose = options.fetch(:verbose, true)
        # Output to file?
        @file_output = options.fetch(:file_output, true)
        # What path to file?
        @output_path = options.fetch(:output_path, ".")
        FileUtils.mkdir_p(@output_path) if @output_path

        @output_file_path = File.join(@output_path, ".minitest_failed_tests.txt")
      end

      def record(test)
        tests << test
      end

      def report
        super

        failure_paths = []
        file_output   = []
        curdir        = FileUtils.pwd

        tests.each do |test|
          next if test.skipped?
          next if test.failure.nil?

          # DEBUG OUTPUT STR
          # p '============================================='
          # p "Failure:\n#{test.class}##{test.name} [#{test.failure.location}]\n#{test.failure.class}: #{test.failure.message}"
          # p '============================================='

          failure_file_location = find_failure_location(test, curdir)
          failure_paths << failure_file_location if failure_file_location
        end

        output_results(failure_paths, file_output)
        File.write(@output_file_path, file_output.join("\n"), encoding: "UTF-8")
      end

      private

      def find_failure_location(test, curdir)
        # Build a haystack string from failures and errors to find test file location in
        tmp_haystack = []
        tmp_haystack << test.failure.location
        tmp_haystack << test.to_s
        # Add filtered backtrace unless it is an unexpected error, which do not have a useful trace
        tmp_haystack << filter_backtrace(test.failure.backtrace).join unless test.failure.is_a?(MiniTest::UnexpectedError)

        # Get failure location as best we can from haystack
        if @include_line_numbers
          failure_file_location = tmp_haystack.join[/(.+_test\.rb:[0-9]+)/, 1]
        else
          failure_file_location = tmp_haystack.join[/(.+_test\.rb):[0-9]+/, 1]
        end

        return unless failure_file_location

        # Make path relative if absolute
        failure_file_location.gsub!(curdir, "")
        failure_file_location.gsub!(%r{^/}, "")

        failure_file_location
      end

      def output_results(failure_paths, file_output)
        return if failure_paths.empty?

        _puts("")
        headline = @include_line_numbers ? "Failed tests: #{failure_paths.count} (seed #{@options[:seed]}):" : "Failed test files: #{failure_paths.count} (seed #{@options[:seed]}):"
        _puts(headline)
        failure_paths.uniq.each do |file_path|
          file_output << file_path.to_s
          _puts red(file_path.strip)
        end
      end

      def _puts(str)
        return unless @verbose

        puts(str)
      end

      def print_padded_comment(line)
        puts "##{pad(line)}"
      end

      def color?
        return @color if defined?(@color)

        @color = @options.fetch(:color) do
          io.tty? && (
            ENV["TERM"] =~ /^screen|color/ ||
              ENV["EMACS"] == "t"
          )
        end
      end

      def green(string)
        color? ? ANSI::Code.green(string) : string
      end

      def yellow(string)
        color? ? ANSI::Code.yellow(string) : string
      end

      def red(string)
        color? ? ANSI::Code.red(string) : string
      end
    end
  end
end
