require 'minitest_helper'

class TestArtTracksUtils < MiniTest::Unit::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::ArtTracksUtils::VERSION
  end

  def test_it_does_something_useful
    assert true
  end
end
