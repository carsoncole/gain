require "test_helper"

class TradeTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @security = create(:security)
    @security_2 = create(:security)
  end

  test "quantity sign" do
    trade = build(:trade, trade_type: 'Sell')
    assert_equal 100, trade.quantity
    trade.valid?
    assert_equal -100, trade.quantity

    trade.quantity = -200
    trade.valid?
    assert_equal -200, trade.quantity
  end

  test "buy?" do
    trade = build(:trade, trade_type: 'Buy')
    assert trade.buy?
    assert_not trade.sell?
  end

  test "sell?" do
    trade = build(:trade, trade_type:'Sell')
    assert trade.sell?
  end

  test "amount calculation with no fees, commissions" do
    trade = create(:trade, price: 10, quantity: 100)
    assert_equal 1000, trade.amount
  end

  test "amount calculation" do
    trade = create(:trade, account: @account, fee: 15, other: 20)
    assert_equal 1035, trade.amount
  end

  test "quantity balance for sequential BUY trades" do
    trade_1 = create(:trade, account: @account, security: @security, quantity: 10, price: 10)
    assert_equal 10, trade_1.reload.quantity_balance
    trade_2 = create(:trade, account: @account, quantity: 150, security: @security)
    assert_equal 160, trade_2.reload.quantity_balance
    # additional trades in other securities/accounts
    create(:trade, account: @account, quantity: 1000, security: @security_2)
    create(:trade)

    trade = create(:trade, account: @account, quantity: 25, security: @security)
    assert_equal 185, trade.reload.quantity_balance
  end

  test "quantity balance for sequential SELL trades" do
    trade = create(:trade, account: @account, security: @security, quantity: 25, trade_type: 'Sell')
    assert_equal -25, trade.reload.quantity_balance

    # additional trades in other securities/accounts
    create(:trade, account: @account, quantity: 1000, security: @security_2)
    create(:trade)

    trade = create(:trade, account: @account, quantity: 15, security: @security, trade_type: 'Sell')
    assert_equal -40, trade.reload.quantity_balance
  end

  test "quantity balance for buys and sells with negative holdings" do
    trade_1 = create(:trade, account: @account, security: @security, quantity: 100)
    trade_2 = create(:trade, account: @account, security: @security, quantity: 150, trade_type: 'Sell')
    assert_equal -50, trade_2.reload.quantity_balance

    trade_3 = create(:trade, account: @account, security: @security, quantity: 100, trade_type: 'Sell')
    assert_equal -150, trade_3.reload.quantity_balance

    trade_4 = create(:trade, account: @account, security: @security, quantity: 200)
    assert_equal 50, trade_4.reload.quantity_balance
  end

  test "quantity balance on non sequential entered day BUY trades" do
    trade_3 = create(:trade, account: @account, security: @security, quantity: 25, date: Date.today)
    assert_equal 25, trade_3.reload.quantity_balance

    trade_1 = create(:trade, account: @account, quantity: 150, security: @security, date: Date.today- 2.days)
    assert_equal 150, trade_1.reload.quantity_balance

    trade_3.reload
    assert_equal 175, trade_3.reload.quantity_balance

    trade_2 = create(:trade, account: @account, security: @security, quantity: 10, date: Date.today- 2.days)
    assert_equal 160, trade_2.reload.quantity_balance
    trade_3.reload
    assert_equal 185, trade_3.reload.quantity_balance
  end

  test "quantity balance on non sequential entered SELL trades" do
    trade_3 = create(:sell_trade, account: @account,security: @security, quantity: 50, date: Date.today)
    assert_equal -50, trade_3.reload.quantity_balance

    trade_1 = create(:buy_trade, account: @account,quantity: 150, security: @security, date: Date.today- 2.days)
    assert_equal 150, trade_1.reload.quantity_balance

    trade_3.reload
    assert_equal 100, trade_3.reload.quantity_balance

    trade_2 = create(:sell_trade, account: @account, security: @security, quantity: 10, date: Date.today- 2.days)
    assert_equal 140, trade_2.reload.quantity_balance
    trade_3.reload
    assert_equal 90, trade_3.reload.quantity_balance
  end

  test "quantity balance updated BUY trades" do
    trade_1 = create(:trade, account: @account, quantity: 10, security: @security, date: Date.today - 5.days)
    trade_2 = create(:trade, account: @account, quantity: 15, security: @security, date: Date.today - 3.days)
    trade_3 = create(:trade, account: @account, quantity: 25, security: @security)
    assert_equal 25, trade_2.reload.quantity_balance
    assert_equal 50, trade_3.reload.quantity_balance

    trade_3.update(date: Date.today - 10.days)
    assert_equal 25, trade_3.reload.quantity_balance
    assert_equal 35, trade_1.reload.quantity_balance
    assert_equal 50, trade_2.reload.quantity_balance

    trade_1.update(date: Date.today)
    assert_equal 25, trade_3.reload.quantity_balance
    assert_equal 40, trade_2.reload.quantity_balance
    assert_equal 50, trade_1.reload.quantity_balance
  end

  test "quantity balance updated BUY to SELL trade" do
    trade_1 = create(:trade, account: @account, quantity: 10, security: @security, date: Date.today - 5.days)
    trade_2 = create(:trade, account: @account, quantity: 15, security: @security, date: Date.today - 3.days)
    trade_3 = create(:trade, account: @account, quantity: 25, security: @security)
    assert_equal 25, trade_2.reload.quantity_balance
    assert_equal 50, trade_3.reload.quantity_balance

    trade_2.update(trade_type: 'Sell')
    assert_equal -5, trade_2.reload.quantity_balance
    assert_equal 20, trade_3.reload.quantity_balance
  end
end
