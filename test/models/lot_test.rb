require "test_helper"

class LotTest < ActiveSupport::TestCase
  def setup
    @trade = create(:buy_trade)
  end

  test "lot" do
    assert_equal 1, Lot.count
    assert_equal 1000, Lot.last.amount
    assert_equal 100, Lot.last.quantity
  end

  test "positive lot full offset" do
    create(:sell_trade, quantity: 100, account_id: @trade.account_id, security_id: @trade.security_id)
    assert_equal 0, Lot.count
  end

  test "positive lot partial offset" do
    create(:sell_trade, quantity: 5, account_id: @trade.account_id, security_id: @trade.security_id)
    assert_equal 1, Lot.count
    assert_equal 95, Lot.last.quantity
  end

  test "positive lot excess offset" do
    create(:sell_trade, quantity: 150, account_id: @trade.account_id, security_id: @trade.security_id)
    assert_equal 1, Lot.count
    assert_equal -50, Lot.last.quantity
  end

  test "negative lot full offset" do
    trade_2 = create(:sell_trade, quantity: 10)
    create(:buy_trade, quantity: 10, account_id: trade_2.account_id, security_id: trade_2.security_id)
    assert_equal 1, Lot.count
  end

  test "negative lot partial offset" do
    trade_2 = create(:sell_trade, quantity: 10)
    create(:buy_trade, quantity: 5, account_id: trade_2.account_id, security_id: trade_2.security_id)
    assert_equal 2, Lot.count
    assert_equal -5, Lot.last.quantity
  end

  test "negative lot excess offset" do
    trade_2 = create(:sell_trade, quantity: 10)
    create(:buy_trade, quantity: 15, account_id: trade_2.account_id, security_id: trade_2.security_id)
    assert_equal 2, Lot.count
    assert_equal 5, Lot.last.quantity
  end

  test "removal of lot on changed security id update" do
    security = create(:security, user_id: @trade.account.user_id)
    trade_2 = create(:buy_trade, account_id: @trade.account_id, security: security)
    assert_equal 2, Lot.count
    assert_equal 2, Lot.distinct.pluck(:security_id).count
    trade_2.update(security_id: @trade.security_id)
    assert_equal 1, Lot.distinct.pluck(:security_id).count
  end

  test "status of lots after update" do
    trade_1 = create(:buy_trade, quantity: 25)
    trade_2 = create(:sell_trade, account_id: trade_1.account_id, security_id: trade_1.security_id, quantity: 15)
    assert_equal 2, Lot.count
    trade_2.update(quantity: 10)
    assert_equal 15, trade_1.reload.lot.quantity
    assert_not trade_2.reload.lot
  end

  test "new trade prior to existing trades" do
    trade_1 = create(:buy_trade, quantity: 25)
    trade_2 = create(:sell_trade, account_id: trade_1.account_id, security_id: trade_1.security_id, quantity: 15)
    trade_3 = create(:buy_trade, date: Date.today - 1.day, account_id: trade_1.account_id, security_id: trade_1.security_id, quantity: 20)
    assert_equal 25, trade_1.reload.lot.quantity
    assert_equal 5, trade_3.reload.lot.quantity
    assert_equal 3, Lot.count
  end

  test "quantity balances matching lot balances" do
    security = create(:security)
    account = create(:account, user: security.user)
    balance = 0
    (rand(25) + 10).times do
      trade_type = ['Buy', 'Sell'][rand(2)]
      quantity = rand(200) + 10
      trade = create(:trade, quantity: quantity, security: security, account: account, trade_type: trade_type)
      balance += trade.quantity
    end
    assert_equal 1, account.positions.count
    assert_equal balance, account.positions.first.quantity
  end

  test "conversion with security updated on lot" do
    assert_equal @trade.security_id, Lot.first.security_id
    new_security = create(:security, user: @trade.account.user)
    trade_2 = build(:conversion_trade, conversion_to_quantity: 100, conversion_from_quantity: 100, conversion_to_security_id: new_security.id, account: @trade.account, security: @trade.security)
    trade_2.add_conversion_trades!
    assert_equal 1, Lot.count
    assert_equal new_security.id, Lot.first.security_id
  end

  test "destroying all lots and reseting them" do
    security = create(:security)
    account = create(:account, user: security.user)
    create_list(:buy_trade, 20, account: account, security: security)
    assert_equal 21, Lot.count
    Lot.destroy_all
    Lot.reset_lots!(account, security)
    assert_equal 20, Lot.count
  end

  test "split" do
    #TODO
  end
end
