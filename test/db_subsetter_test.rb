require 'test_helper'

class DbSubsetterTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DbSubsetter::VERSION
  end
end
