require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "current positions" do
    trade = create(:trade)
    assert_equal Trade, Position.all(Date.today).first.class
  end
end
