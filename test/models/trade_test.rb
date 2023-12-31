require "test_helper"

class TradeTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @user = @account.user
    @security = create(:security, user: @user)
    @security_2 = create(:security, user: @user)
  end

  test "quantity sign" do
    trade = build(:sell_trade, security: @security)
    trade.save
    assert_equal -100, trade.reload.quantity
  end

  test "quantity sign on updates" do
    trade = create(:sell_trade)
    trade.update(quantity: 100)
    assert_equal -100, trade.quantity
    trade.update(amount: -1000)
    assert_equal -100, trade.quantity
  end

  test "buy?" do
    trade = build(:buy_trade)
    assert trade.buy?
    assert trade.buy_sell?
    assert trade.buy_sell_conversion?
    assert_not trade.sell?
  end

  test "sell?" do
    trade = build(:sell_trade)
    assert trade.sell?
    assert trade.buy_sell?
  end

  test "split?" do
    trade = build(:split_trade)
    assert trade.split?
    assert_not trade.buy_sell?
  end

  test "conversion?" do
    trade = build(:conversion_trade)
    assert trade.conversion?
    assert trade.buy_sell_conversion?
  end

  test "invalid trade" do
    trade = build(:buy_trade, price: nil, quantity: nil)
    assert_not trade.valid?
    assert trade.errors.full_messages.include? "Price can't be blank"
    assert trade.errors.full_messages.include? "Quantity can't be blank"
  end

  test "conversion validation" do
    trade = build(:conversion_trade, security: create(:security), price: 10)
    assert_not trade.valid?
    assert_equal "Price must be blank", trade.errors.full_messages.first

    trade = build(:conversion_trade, security: create(:security), amount: 10)
    assert_not trade.valid?
    assert_equal "Amount must be blank", trade.errors.full_messages.first
  end

  test "amount calculation with no fees, commissions" do
    trade = create(:trade, price: 10, quantity: 100)
    assert_equal 1000, trade.amount
  end

  test "amount calculation" do
    trade = create(:trade, account: @account, fee: 15, other: 20)
    assert_equal 1035, trade.amount
  end

  test "price recalculation when amount provided" do
    trade = create(:trade, account: @account, quantity: 10, price: 10, fee: 10, other: 10, amount: 200)
    assert_equal 200, trade.amount
    assert_equal 18, trade.price
  end

  test "amount on sell less fees" do
    trade = create(:sell_trade, account: @account, quantity: 10, price: 10, fee: 10, other: 10)
    assert_equal 80, trade.amount
  end

  test "price adjusted off amount" do
    trade = create(:buy_trade, account: @account, quantity: 15, price: 10, fee: 10, other: 10, amount: 237.5)
    assert_equal 14.5, trade.price

    trade = create(:sell_trade, account: @account, quantity: 15, price: 10, fee: 10, other: 10, amount: 300)
    assert_equal 21.33333, trade.price
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
    trade = create(:sell_trade, account: @account, security: @security, quantity: 25)
    assert_equal -25, trade.reload.quantity_balance

    # additional trades in other securities/accounts
    create(:trade, account: @account, quantity: 1000, security: @security_2)
    create(:trade)

    trade = create(:sell_trade, account: @account, quantity: 15, security: @security)
    assert_equal -40, trade.reload.quantity_balance
  end

  test "quantity balance for buys and sells with negative holdings" do
    trade_1 = create(:trade, account: @account, security: @security, quantity: 100)
    trade_2 = create(:sell_trade, account: @account, security: @security, quantity: 150)
    assert_equal -50, trade_2.reload.quantity_balance

    trade_3 = create(:sell_trade, account: @account, security: @security, quantity: 100)
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

  test "quantity balance after deleted trade" do
    trade_1 = create(:trade, account: @account, quantity: 10, security: @security, date: Date.today - 5.days)
    trade_2 = create(:trade, account: @account, quantity: 15, security: @security, date: Date.today - 3.days)
    trade_3 = create(:trade, account: @account, quantity: 20, security: @security, date: Date.today - 3.days)
    trade_4 = create(:trade, account: @account, quantity: 25, security: @security)
    trade_1.destroy
    assert_equal 15, trade_2.reload.quantity_balance
    assert_equal 35, trade_3.reload.quantity_balance
    assert_equal 60, trade_4.reload.quantity_balance
  end

  test "split trade followed by buy and sell" do
    trade_1 = create(:buy_trade, quantity: 100, security: @security, account: @account)
    trade_2 = create(:split_trade, account: @account, security: @security, split_new_shares: 1000)

    assert_equal 1000, @account.last_trade(@security).quantity_balance
    trade_3 = create(:buy_trade, quantity: 200, account: @account, security: @security)
    assert_equal 1200, trade_3.reload.quantity_balance
    trade_4 = create(:sell_trade, quantity: 50, account: trade_1.account, security: @security)
    assert_equal 1150, trade_4.reload.quantity_balance
  end

  test "conversion of full quantity to new security" do
    trade_1 = create(:buy_trade, account: @account, security: @security, quantity: 10)
    assert_equal 0, @security_2.trades.count
    assert_equal trade_1.security_id, Position.all(trade_1.account).first.security.id
    trade_2 = create(:conversion_trade, conversion_to_quantity: 10, conversion_from_quantity: 10, conversion_to_security_id: @security_2.id, account: @account, security: @security)

    assert_equal 3, Trade.count
    assert_equal 1, @security_2.trades.count
    assert_equal 10, @account.trades.where(security_id: @security_2.id).last.quantity_balance
    assert_equal 1, Position.all(trade_1.account).count
    assert_equal @security_2.id, Position.all(trade_1.account).first.security.id
  end

  test "partial conversion" do
    trade_1 = create(:buy_trade, account: @account, security: @security, quantity: 100, date: Date.today - 5.days)
    trade_2 = create(:conversion_trade, conversion_to_quantity: 20, conversion_from_quantity: 20, conversion_to_security_id: @security_2.id, account: @account, security: @security)

    assert_equal 20, @account.last_trade(@security_2).quantity_balance
    assert_equal 80, @account.last_trade(@security).quantity_balance
  end

  test "conversion of full quantity to higher number of shares" do
    trade_1 = create(:buy_trade, account: @account, security: @security, quantity: 100)
    trade_2 = create(:conversion_trade, conversion_to_quantity: 200, conversion_from_quantity: 100, conversion_to_security_id: @security_2.id, account: @account, security: @security)

    assert_equal 200, @account.last_trade(@security_2).quantity_balance
    assert_equal 0, @account.last_trade(@security).quantity_balance
  end

  test "conversion of multiple lots" do
    trades = create_list(:buy_trade, 5, account: @account, security: @security, quantity: 100, date: Date.today-4.days)
    trade_2 = create(:conversion_trade, conversion_to_quantity: 500, conversion_from_quantity: 500, conversion_to_security_id: @security_2.id, account: @account, security: @security)

    assert_equal 500, @account.trades.where(security_id: @security_2.id).sum(:quantity)
    assert_equal 500, @account.last_trade(@security_2).quantity_balance
    assert_equal 0, @account.last_trade(@security).quantity_balance
  end

  test "trades entered out of order with conversion" do
    trade_5 = create(:buy_trade, account: @account, security: @security, quantity: 150, date: Date.new(2023,7,1))
    trade_6 = create(:conversion_trade, account: @account, security: @security, conversion_to_security_id: @security_2.id, conversion_from_quantity: 150, conversion_to_quantity: 450, date: Date.new(2023,7,20))

    trade_1 = create(:buy_trade, account: @account, security: @security, quantity: 125, date: Date.new(2023,8,1))
    trade_4 = create(:sell_trade, account: @account, security: @security, quantity: 100, date: Date.new(2023,8,7))
    trade_2 = create(:buy_trade, account: @account, security: @security, quantity: 200, date: Date.new(2023,8,3))
    trade_3 = create(:sell_trade, account: @account, security: @security, quantity: 100, date: Date.new(2023,8,5))

    assert_equal 125, trade_1.reload.quantity_balance
    assert_equal 325, trade_2.reload.quantity_balance
    assert_equal 225, trade_3.reload.quantity_balance
    assert_equal 125, trade_4.reload.quantity_balance
    assert_equal 150, trade_5.reload.quantity_balance
  end
end
