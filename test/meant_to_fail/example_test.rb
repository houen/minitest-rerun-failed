# frozen_string_literal: true

require "test_helper"

Minitest::Reporters.use!(
  [
    Minitest::Reporters::ProgressReporter.new,
    Minitest::Reporters::FailedTestsReporter.new
  ]
)

class ExampleTest < Minitest::Test
  def test_one
    flunk
  end

  def test_two
    raise
  end

  def test_three
    flunk
  end

  def test_four
    flunk
  end

  def test_five
    flunk
  end

  def test_six
    flunk
  end

  def test_seven
    flunk
  end

  def test_eight
    flunk
  end

  def test_nine
    flunk
  end
end
