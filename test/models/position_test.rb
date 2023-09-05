require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "current positions" do
    trade = create(:trade)
    assert_equal Array, Position.security_ids(trade.account,Date.today).class
    assert_equal trade.security_id, Position.security_ids(trade.account,Date.today).first
    assert_equal 1, Position.all(trade.account).count
  end

  test "positions as of" do
    account = create(:account)
    trade = create(:trade, account: account, date: Date.today - 6.months)
    user = account.user_id
    trade = create(:trade, account: account, date: Date.today - 1.month)
    trade = create(:trade, account: account, date: Date.today)
    assert_equal 1, Position.all(account, Date.today - 6.months).count
    assert_equal 2, Position.all(account, Date.today - 1.month).count
    assert_equal 3, Position.all(account).count
  end
end
