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
    #   Minitest::Reporters.use! [
    #     Minitest::Reporters::ProgressReporter.new,
    #     Minitest::Reporters::FailedTestsReporter.new(verbose: true, include_line_numbers: true)
    #   ]
    #
    #   Now after a failed test run, rerun failed tests only with: `bin/rerun_failed_tests`
    #
    class FailedTestsReporter < Minitest::Reporters::BaseReporter
      def initialize(options = {})
        super
        @options = options

        # Include line numbers? (failed_test.rb:42 or just failed_test.rb)
        @include_line_numbers = options.fetch(:include_line_numbers, true)
        # Output to console?
        @verbose = options.fetch(:verbose, true)
        # Output to file?
        @file_output = options.fetch(:file_output, true)
        # What path to file?
        @output_path = options.fetch(:output_path, ".")
        FileUtils.mkdir_p(@output_path) if @file_output && @output_path

        @output_file_path = File.join(@output_path, ".minitest_failed_tests.txt")
      end

      def report
        super

        curdir        = FileUtils.pwd
        failure_paths = failed_test_locations(curdir)
        output_paths  = failure_paths.map(&:strip).uniq

        output_results(failure_paths.count, output_paths)
        write_file_output(output_paths) if @file_output
      end

      private

      def failed_test_locations(curdir)
        tests.filter_map do |test|
          next if test.skipped?
          next if test.failure.nil?

          find_failure_location(test, curdir)
        end
      end

      def find_failure_location(test, curdir)
        # Build a haystack string from failures and errors to find test file location in
        tmp_haystack = []
        tmp_haystack << test.failure.location
        tmp_haystack << test.to_s
        # Add filtered backtrace unless it is an unexpected error, which do not have a useful trace
        unless test.failure.is_a?(Minitest::UnexpectedError)
          tmp_haystack << filter_backtrace(test.failure.backtrace).join
        end

        # Get failure location as best we can from haystack
        if @include_line_numbers
          regex_keeping_line_numbers = /(.+_test\.rb:[0-9]+)/
          failure_file_location = tmp_haystack.join[regex_keeping_line_numbers, 1]
        else
          regex_removing_line_numbers = /(.+_test\.rb):[0-9]+/
          failure_file_location = tmp_haystack.join[regex_removing_line_numbers, 1]
        end

        return unless failure_file_location

        # Make path relative if absolute
        failure_file_location.gsub!(curdir, "")
        failure_file_location.gsub!(%r{^/}, "")

        failure_file_location.to_s.strip
      end

      def output_results(failure_count, output_paths)
        return if output_paths.empty?

        _puts("")
        headline =
          if @include_line_numbers
            "Failed tests: #{failure_count} (seed #{@options[:seed]}):"
          else
            "Failed test files: #{failure_count} (seed #{@options[:seed]}):"
          end
        _puts(headline)

        output_paths.each do |file_path|
          _puts color_red(file_path)
        end
      end

      def write_file_output(file_output)
        output = file_output.empty? ? "" : "#{file_output.join("\n")}\n"
        File.write(@output_file_path, output, encoding: "UTF-8")
      end

      def _puts(str)
        return unless @verbose

        puts(str)
      end

      def color?
        return @color if defined?(@color)

        @color = @options.fetch(:color) do
          io.tty? && (
            ENV.fetch("TERM", nil) =~ /^screen|color/ ||
              ENV.fetch("EMACS", nil) == "t"
          )
        end
      end

      def color_red(string)
        color? ? ANSI::Code.red(string) : string
      end
    end
  end
end
