# frozen_string_literal: true

require "test_helper"

Minitest::Reporters.use!(
  [
    Minitest::Reporters::ProgressReporter.new,
    Minitest::Reporters::FailedTestsReporter.new
  ]
)

class AnotherExampleTest < Minitest::Test
  def test_one
    flunk
  end

  def test_two
    raise
  end

  def test_three
    flunk
  end
end
