# minitest-rerun-failed
![master branch CI](https://github.com/houen/minitest-rerun-failed/actions/workflows/main.yml/badge.svg?branch=master)

Easy rerun of failed tests with minitest.

![Example screenshot](assets/screenshot.png)

## Goals
- Outputs all failed tests in short summary at end of test run.
  - To console and / or to file
  - Optionally includes line numbers
- Lists seed of run for rerun.
- [TODO] Executable for running only failed tests
  - Until then, use something like 
    - `ruby $(cat .minitest_failed_tests.txt)`
    - `bundle exec rails test $(cat .minitest_failed_tests.txt)`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minitest-rerun-failed'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install minitest-rerun-failed

## Usage

Use it like any Minitest::Reporters like such:

```ruby
Minitest::Reporters.use! [
  Minitest::Reporters::ProgressReporter.new, # This is just my preferred reporter. Use the one(s) you like.
  Minitest::Reporters::FailedTestsReporter.new(verbose: true, include_line_numbers: true)
]
```

## Rails Usage

In your `test_helper.rb` file, add the following lines 

```ruby
require "minitest_rerun_failed"

Minitest::Reporters.use!(
  [Minitest::Reporters::DefaultReporter.new(color: true),
   Minitest::Reporters::FailedTestsReporter.new(verbose: true, include_line_numbers: true, output_path: "tmp")
  ],
  ENV,
  Minitest.backtrace_filter
)

```



### Options
- include_line_numbers: Include line numbers in outputs. Defaults to true
- verbose: Output to stdout. Defaults to true
- file_output: Output to file. Defaults to true
- output_path: Path to place output files in. Defaults to '.'

## Other
### Why line numbers instead of test names? What if the lines change as I am fixing things?
Line numbers were much easier to implement.
If you find a good way to output test names instead, please open a PR with tests to add it as an option.

As for if line numbers change, the most likely outcome is that the whole file will simply be run instead of a single test.
You can also use the option `include_line_numbers: false` to always output whole files for greater safety.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/houen/minitest_rerun_failed.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## TODO
- Executable for rerun? (https://stackoverflow.com/a/65707495)
- Rerun with same seed
- Minitest-reporters or minitest plugin?

https://stackoverflow.com/questions/19910533/minitest-rerun-only-failed-tests
