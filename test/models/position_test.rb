require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "current positions" do
    trade = create(:trade)
    assert_equal Array, Position.security_ids(trade.account,Date.today).class
  end
end
