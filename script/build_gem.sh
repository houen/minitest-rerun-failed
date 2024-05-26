#!/usr/bin/env bash

gem build minitest_rerun_failed.gemspec
gem install minitest-rerun-failed -v "0.2.3.pre"

echo "Built and installed locally."
echo "Now run gem push minitest-rerun-failed-[VERSION].gem"

