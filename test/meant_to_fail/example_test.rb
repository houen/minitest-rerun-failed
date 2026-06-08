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
    assert false
  end

  def test_two
    raise
  end

  def test_three
    assert false
  end

  def test_four
    assert false
  end

  def test_five
    assert false
  end

  def test_six
    assert false
  end

  def test_seven
    assert false
  end

  def test_eight
    assert false
  end

  def test_nine
    assert false
  end
end
