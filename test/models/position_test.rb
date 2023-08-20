require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "current positions" do
    trade = create(:trade)
    assert_equal Array, Position.all(trade.account,Date.today).class
  end
end
