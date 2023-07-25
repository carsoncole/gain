require "test_helper"

class SecurityTest < ActiveSupport::TestCase
  test "symbol upcasing" do
    security = create(:security, symbol: 'iBm')
    assert_equal "IBM", security.symbol
  end
end
