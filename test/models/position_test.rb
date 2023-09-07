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

  test "positions on prior dates after split" do
    account = create(:account)
    security = create(:security, user: account.user)
    trade = create(:trade, account: account, date: Date.today - 6.months, security: security, quantity: 100)
    user = account.user_id
    trade = create(:trade, account: account, date: Date.today - 1.month, security: security, quantity: 100)
    trade = create(:trade, account: account, date: Date.today, security: security, quantity: 100)
    assert_equal 300, Position.all(account).first.quantity
    assert_equal 100, Position.all(account, Date.today - 5.months).first.quantity

    split = create(:split_trade, account: account, security: security, split_new_shares: 3000)

    assert_equal 1, Position.all(account).count
    assert_equal 3000, Position.all(account).first.quantity
    assert_equal 100, Position.all(account, Date.today - 5.months).first.quantity
  end
end
