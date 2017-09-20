require "test_helper"

class Freno::ThrottlerTest < Freno::Throttler::Test
  def test_that_it_has_a_version_number
    refute_nil ::Freno::Throttler::VERSION
  end
end
