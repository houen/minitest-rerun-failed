## [Unreleased] - 2024-04-20
- Changed: Also strip file paths when writing to .minitest_failed_tests.txt
- Fixed: Strip leading whitespace from failure locations

## [0.2.1] - 2022-12-04
- Set dependency versions with >= so they do not enforce old versions

## [0.2.0] - 2021-09-12
- Add support for Ruby 2.6

## [0.1.3] - 2021-09-09
- Initial release
- Outputs to console
- Outputs to file
- Rerun must be done semi-manually via something like `bundle exec rails test $(cat .minitest_failed_tests.txt)`


