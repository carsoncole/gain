require "test_helper"

class GainLossTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @security = create(:security)
    @security_2 = create(:security)
  end

  test "closing single position with single trade" do
    trade_1 = create(:trade, account: @account, security: @security)
    trade_2 = create(:trade, account: @account, security: @security, quantity: -100, price: 20, trade_type: 'Sell')
    assert_equal 1, @account.gain_losses.count
    assert_equal 1000, trade_2.gain_losses.first.amount
    assert_equal -100, trade_2.gain_losses.last.quantity
    assert_equal 1000, trade_2.gain_losses.last.amount
    assert_equal 1000, @account.gain_losses.sum(:amount)
  end

  test "single partial closing trade" do
    trade_1 = create(:buy_trade, account: @account, security: @security, quantity: 100, price: 10)
    trade_2 = create(:sell_trade, account: @account, security: @security, quantity: 50, price: 20)
    assert_equal 1, @account.gain_losses.count
    assert_equal 500, trade_2.gain_losses.first.amount
    assert_equal -50, trade_2.gain_losses.last.quantity
    assert_equal 500, trade_2.gain_losses.last.amount
    assert_equal 500, @account.gain_losses.sum(:amount)
  end

  test "multiple gains generated by one trade" do
    trade_1 = create(:buy_trade, account: @account, security: @security, quantity: 100, price: 10)
    trade_2 = create(:buy_trade, account: @account, security: @security, quantity: 100, price: 20)
    trade_3 = create(:sell_trade, account: @account, security: @security, quantity: 150, price: 40)
    assert_equal 2, @account.gain_losses.count
    assert_equal 3000, trade_3.gain_losses.first.amount
    assert_equal 1000, trade_3.gain_losses.last.amount
    assert_equal -50, trade_3.gain_losses.last.quantity
    assert_equal 4000, @account.gain_losses.sum(:amount)
  end

  test "over closing a single position" do
    trade_1 = create(:trade, account: @account, security: @security, quantity: 100, price: 10, trade_type: 'Buy')
    trade_2 = create(:trade, account: @account, security: @security, quantity: -150, price: 20, trade_type: 'Sell')
    assert_equal 1, @account.gain_losses.count
    assert_equal 1000, trade_2.gain_losses.first.amount
    assert_equal -100, trade_2.gain_losses.first.quantity
    assert_equal 1000, trade_2.gain_losses.last.amount
  end

  test "reversing accounting on destroying single trade" do
    trade_1 = create(:trade, account: @account, security: @security, quantity: 100, price: 10, trade_type: 'Buy')
    trade_2 = create(:trade, account: @account, security: @security, quantity: -100, price: 20, trade_type: 'Sell')
    trade_2.destroy
    assert_equal 0, @account.gain_losses.count
  end

  test "reversing accounting and recalcing subsequent trades on destroying single trade" do
    trade_1 = create(:trade, account: @account, security: @security, quantity: 50, price: 10, trade_type: 'Buy')
    trade_2 = create(:trade, account: @account, security: @security, quantity: 50, price: 20, trade_type: 'Buy')
    trade_3 = create(:trade, account: @account, security: @security, quantity: 50, price: 40, trade_type: 'Buy')
    trade_4 = create(:trade, account: @account, security: @security, quantity: 50, price: 20, trade_type: 'Sell')
    assert_equal 1, @account.gain_losses.count
    trade_5 = create(:trade, account: @account, security: @security, quantity: 10, price: 60, trade_type: 'Sell')
    assert_equal 2, @account.gain_losses.count
    trade_6 = create(:trade, account: @account, security: @security, quantity: 5, price: 70, trade_type: 'Sell')
    assert_equal 3, @account.gain_losses.count
    assert_equal 500, trade_4.reload.gain_losses.first.amount
    assert_equal 400, trade_5.reload.gain_losses.first.amount
    assert_equal 250, trade_6.reload.gain_losses.first.amount
    trade_2.destroy
    assert_equal 200, trade_5.reload.gain_losses.first.amount
    assert_equal 150, trade_6.reload.gain_losses.first.amount
  end

  test "buy sell trades all at same price"  do
    create_list(:buy_trade, 25, account: @account, quantity: rand(1000), price: 10, security: @security)
    create_list(:sell_trade, 15, account: @account, quantity: rand(1000), price: 10, security: @security)

    assert_equal 0, @account.gain_losses.sum(:amount)
  end

  test "multiple trades with different securities" do
    @total_quantity_1, @total_amount_1, @total_quantity_2, @total_amount_2 = 0, 0, 0, 0
    @account = create(:account)
    security_1, security_2 = create(:security), create(:security)

    (0..4).each do |t|
      trade = create(:trade, account: @account, security: security_1, quantity: 25)
      @total_quantity_1 += trade.quantity
      @total_amount_1 += trade.amount
    end

    (0..4).each do |t|
      trade = create(:trade, account: @account, security: security_2, quantity: 100)
      @total_quantity_2 += trade.quantity
      @total_amount_2 += trade.amount
    end

    @trade_1 = create(:trade, account: @account, security: security_1, trade_type: 'Sell', quantity: 50)
    @trade_2 = create(:trade, account: @account, security: security_2, trade_type: 'Sell', quantity: 100)
    @trade_3 = create(:trade, account: @account, security: security_1, trade_type: 'Sell', quantity: 25)

    assert_equal 2, @trade_1.reload.gain_losses.count
    assert_equal 1, @trade_2.reload.gain_losses.count
    assert_equal 4, @account.reload.gain_losses.count
  end

  test "buys followed by sells followed by buys" do
    create_list(:trade, 10, account: @account, security: @security)
    create_list(:trade, 5, account: @account, security: @security, trade_type: 'Sell')
    create_list(:trade, 5, account: @account, security: @security)
    assert_equal 0, @account.gain_losses.sum(:amount)
  end

  test "buying then overselling" do
    create(:buy_trade, account: @account, security: @security, quantity: 10, price: 10)
    create(:sell_trade, account: @account, security: @security, quantity: 20, price: 20)
    assert_equal 100, @account.gain_losses.first.amount
  end

  test "selling then overbuying" do
    trade_1 = create(:sell_trade, account: @account, security: @security, quantity: 10, price: 20)
    trade_2 = create(:buy_trade, account: @account, security: @security, quantity: 20, price: 10)
    assert_equal 100, @account.gain_losses.first.amount
  end

  # creates random collection of 10 each buy/sells trades, with a price of 10 that should sum to 0
  test "multiple buy sells" do
    transactions_to_do = []
    buys, sells = 0, 0
    (1..20).each do |t|
      if buys == 10
        type = 'Sell'
      elsif sells == 10
        type = 'Buy'
      else
        type = ['Buy', 'Sell'][rand(2)]
      end
      buys += 1 if type == 'Buy'
      sells += 1 if type == 'Sell'
      transactions_to_do.insert(rand(transactions_to_do.length), type)
    end
    transactions_to_do.each do |type|
      create(:trade, trade_type: type, quantity: 10, security: @security, account: @account)
    end

    assert_equal 10, @account.gain_losses.count
    assert_equal 0, @account.gain_losses.sum(:amount)
  end

  test "conversion of full security quantity" do
    create(:buy_trade, account: @account, security: @security, quantity: 100)
    conversion = create(:conversion_trade, conversion_to_quantity: 100, conversion_from_quantity: 100, conversion_to_security_id: @security_2.id, account: @account, security: @security)
    assert_equal 0, GainLoss.sum(:amount)
    create(:sell_trade, account: @account, security: @security_2, quantity: 100, price: 20)
    assert_equal 1000, @account.gain_losses.where(security: @security_2).sum(:amount)
  end

  test "conversion of partial quantity" do
    create(:buy_trade, account: @account, security: @security, quantity: 1000)
    conversion = create(:conversion_trade, conversion_to_quantity: 100, conversion_from_quantity: 100, conversion_to_security_id: @security_2.id, account: @account, security: @security)

    assert_equal 0, GainLoss.sum(:amount)
    create(:sell_trade, account: @account, security: @security_2, quantity: 100, price: 20)
    assert_equal 1000, @account.gain_losses.where(security: @security_2).sum(:amount)
  end

  test "conversion of partial quantity with 2 to 1 conversion ratio" do
    create(:buy_trade, account: @account, security: @security, quantity: 1000, price: 10)
    conversion = create(:conversion_trade, conversion_to_quantity: 200, conversion_from_quantity: 100, conversion_to_security_id: @security_2.id, account: @account, security: @security)

    assert_equal 0, GainLoss.sum(:amount)
    create(:sell_trade, account: @account, security: @security_2, quantity: 100, price: 20)
    assert_equal 1500, @account.gain_losses.where(security: @security_2).sum(:amount)
    assert_equal 0, @account.gain_losses.where(security: @security).sum(:amount)
    create(:sell_trade, account: @account, security: @security, quantity: 100, price: 20)
    assert_equal 1000, @account.gain_losses.where(security: @security).sum(:amount)
  end

  test "short term" do
    create(:buy_trade, account: @account, security: @security, quantity: 100, price: 10, date: Date.today-300.days)
    create(:sell_trade, account: @account, security: @security, quantity: 100, price: 20)
    assert_equal 1, GainLoss.short_term.count
    assert_equal 0, GainLoss.long_term.count
  end

  test "long term" do
    create(:buy_trade, account: @account, security: @security, quantity: 100, price: 10, date: Date.today-400.days)
    create(:sell_trade, account: @account, security: @security, quantity: 100, price: 20)
    assert_equal 1, GainLoss.long_term.count
    assert_equal 0, GainLoss.short_term.count
  end
end
