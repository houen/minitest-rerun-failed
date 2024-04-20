# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/real/**/*_test.rb"]
end

Rake::TestTask.new(:tests_meant_to_fail) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/meant_to_fail/**/*_test.rb"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test]
