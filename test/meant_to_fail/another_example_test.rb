# frozen_string_literal: true

require "test_helper"

Minitest::Reporters.use!(
  [
    Minitest::Reporters::ProgressReporter.new,
    Minitest::Reporters::FailedTestsReporter.new
  ]
)

class AnotherExampleTest < Minitest::Test
  def test1
    assert false
  end

  def test2
    raise
  end

  def test3
    assert false
  end
end
