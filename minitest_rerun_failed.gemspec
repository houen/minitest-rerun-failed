# frozen_string_literal: true

require_relative "lib/minitest_rerun_failed/version"

Gem::Specification.new do |spec|
  spec.name          = "minitest-rerun-failed"
  spec.version       = MinitestRerunFailed::VERSION
  spec.authors       = ["Søren Houen"]
  spec.email         = ["s@houen.net"]

  spec.summary       = "Easily rerun failed tests with Minitest"
  spec.homepage      = "https://www.github.com/houen/minitest_rerun_failed"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://www.github.com/houen/minitest_rerun_failed"
  spec.metadata["changelog_uri"] = "https://www.github.com/houen/minitest_rerun_failed/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "minitest", "~> 5.14.4"
  spec.add_dependency "minitest-reporters", "~> 1.4.3"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
