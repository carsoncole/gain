require "test_helper"

class LotTest < ActiveSupport::TestCase
  def setup
    @trade = create(:buy_trade, date: Date.today - 1.day, quantity: 100, price: 10)
    @account = @trade.account
    @security = @trade.security
  end

  test "lot" do
    assert_equal 1, Lot.count
    assert_equal Date.today - 1.day, Lot.last.date
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
    assert_equal 15, trade_1.lots.first.quantity
    assert_not trade_2.lots.first
  end

  test "new trade prior to existing trades" do
    trade_1 = create(:buy_trade, quantity: 25)
    trade_2 = create(:sell_trade, account_id: trade_1.account_id, security_id: trade_1.security_id, quantity: 15)
    trade_3 = create(:buy_trade, date: Date.today - 1.day, account_id: trade_1.account_id, security_id: trade_1.security_id, quantity: 20)
    assert_equal 25, trade_1.lots.first.quantity
    assert_equal 5, trade_3.lots.first.quantity
    assert_equal 3, Lot.count
  end

  test "quantity balances matching lot balances" do
    Trade.destroy_all
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
    assert_equal balance, Lot.sum(:quantity)
  end

  test "conversion with security updated on lot" do
    assert_equal @trade.security_id, Lot.first.security_id
    new_security = create(:security, user: @trade.account.user)
    trade_2 = create(:conversion_trade, conversion_to_quantity: 100, conversion_from_quantity: 100, conversion_to_security_id: new_security.id, account: @trade.account, security: @trade.security)
    assert_equal 3, Trade.count
    assert_equal 1, Lot.count
    assert_equal new_security.id, Lot.first.security_id
  end

  test "reseting lots" do
    security = create(:security)
    account = create(:account, user: security.user)
    create_list(:buy_trade, 20, account: account, security: security)
    assert_equal 21, Lot.count
    Lot.reset_lots!(account)
    assert_equal 21, Lot.count
  end

  test "random trades offsetting same quantity of lots" do
    account = create(:account)
    security = create(:security, user: account.user)
    trades_to_do = []
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
      trades_to_do.insert(rand(trades_to_do.length), type)
    end
    trades_to_do.each do |type|
      create(:trade, trade_type: type, quantity: 10, security: security, account: account)
    end

    assert_equal 0, account.lots.count
  end

  test "split" do
    split = create(:split_trade, account: @trade.account, security: @trade.security, split_new_shares: 1000)
    assert_equal 1000, @trade.account.last_trade(@trade.security).quantity_balance
    lot = @trade.account.lots.last
    assert_equal 1, @trade.account.lots.count
    assert_equal Date.today - 1.day, lot.date
    assert_equal 1000, lot.amount
    assert_equal 1000, lot.quantity
  end

  test "split and sell portion" do
    split = create(:split_trade, account: @trade.account, security: @trade.security, split_new_shares: 1000)
    assert_equal 1000, @trade.account.lots.last.amount
    sell = create(:sell_trade, quantity: 100, price: 10, account: @trade.account, security: @trade.security)
    assert_equal 1, @trade.account.lots.count
    assert_equal 900, @trade.account.lots.last.amount
    assert_equal 900, @trade.account.lots.last.quantity
  end

  test "conversion" do
    assert_equal 100, @trade.lots.first.quantity
    assert_equal 1000, @trade.lots.first.amount
    new_security = create(:security, user: @trade.account.user)
    conversion = create(:conversion_trade, conversion_to_quantity: 75, conversion_from_quantity: 75, conversion_to_security_id: new_security.id, account: @trade.account, security: @trade.security)
    assert_equal 2, @trade.account.lots.count
    assert_equal 25, @trade.lots.first.quantity
    assert_equal 250, @trade.lots.first.amount
    assert_equal 75, @trade.account.lots.last.quantity
    assert_equal 750, @trade.account.lots.last.amount
    assert_equal 1, @trade.account.lots.where(security: new_security).count
    assert_equal 1, @trade.account.lots.where(security: @trade.security).count
    assert_equal 75, @trade.account.lots.where(security: new_security).last.quantity


    incoming_conversion_trade = @trade.account.trades.conversion.where(security_id: conversion.conversion_to_security_id, date: conversion.date).last

    assert incoming_conversion_trade
    assert_not incoming_conversion_trade.conversion_to_security_id
    assert incoming_conversion_trade.conversion_from_security_id
    assert_equal 75, incoming_conversion_trade.quantity
    assert_equal -75, conversion.quantity
  end

  test "conversion of multiple lots" do
    account = @trade.account
    security = @trade.security
    security_2 = create(:security, user: account.user)
    security_3 = create(:security, user: account.user)
    trade_2 = create(:trade, account: account, security: security)
    trade_3 = create(:trade, account: account, security: security)
    trade_4 = create(:trade, account: account, security: security)
    trade_5 = create(:trade, account: account, security: security)
    # 5 trades = 500 shares @ $10
    assert_equal 5, account.lots.count
    assert_equal 5000, account.lots.where(security: security).sum(:amount)
    assert_equal 500, account.lots.where(security: security).sum(:quantity)

    conversion = create(:conversion_trade, conversion_to_quantity: 500, conversion_from_quantity: 500, conversion_to_security_id: security_2.id, account: account, security: security)

    assert conversion.conversion_outgoing?
    assert_equal 5, account.lots.count
    assert_equal 5000, account.lots.where(security: security_2).sum(:amount)
    assert_equal 500, account.lots.where(security: security_2).sum(:quantity)

    conversion = create(:conversion_trade, conversion_to_quantity: 250, conversion_from_quantity: 250, conversion_to_security_id: security_3.id, account: account, security: security_2)

    assert_equal 6, account.lots.count
    assert_equal 3, account.lots.where(security: security_3).count
    assert_equal 2500, account.lots.where(security: security_3).sum(:amount)
    assert_equal 250, account.lots.where(security: security_3).sum(:quantity)
  end

  test "conversion then split and sell portion" do
    assert_equal 100, @trade.account.lots.where(security_id: @trade.security.id).order(:id).first.quantity
    assert_equal 1000, @trade.account.lots.where(security_id: @trade.security.id).order(:id).first.amount

    new_security = create(:security, user: @trade.account.user)
    conversion = create(:conversion_trade, conversion_to_quantity: 75, conversion_from_quantity: 75, conversion_to_security_id: new_security.id, account: @trade.account, security: @trade.security)

    assert_equal 25, @trade.account.lots.where(security_id: @trade.security_id).order(:id).first.quantity
    assert_equal 250, @trade.account.lots.where(security_id: @trade.security_id).order(:id).first.amount
    assert_equal 75, @trade.account.lots.where(security_id: new_security.id).order(:id).first.quantity
    assert_equal 750, @trade.account.lots.where(security_id: new_security.id).order(:id).first.amount

    split = create(:split_trade, account: @trade.account, security: @trade.security, split_new_shares: 250)
    assert_equal 2, @trade.account.lots.count

    assert_equal 250, @trade.account.lots.where(security_id: @trade.security.id).order(:id).first.quantity
    assert_equal 250, @trade.account.lots.where(security_id: @trade.security.id).order(:id).first.amount

    sell = create(:sell_trade, quantity: 25, price: 10, account: @trade.account, security: @trade.security)
    assert_equal 75, @trade.account.lots.where(security_id: new_security.id).order(:id).last.quantity
    assert_equal 750, @trade.account.lots.where(security_id: new_security.id).order(:id).last.amount
  end

  test "split of multiple lots" do
    # @trade = create(:buy_trade, date: Date.today - 1.day, quantity: 100, price: 10)
    trade_2 = create(:trade, price: 15, quantity: 50, account: @account, security: @security)
    trade_3 = create(:trade, price: 20, quantity: 50, account: @account, security: @security)
    trade_4 = create(:trade, price: 25, quantity: 50, account: @account, security: @security)
    amount = @account.lots.where(security: @security).sum(:amount)
    split = create(:split_trade, account: @trade.account, security: @trade.security, split_new_shares: 2500)

    assert_equal 4, @account.lots.count
    assert_equal 2500, @account.lots.where(security: @security).sum(:quantity)
    assert amount, @account.lots.where(security: @security).sum(:amount)
  end

  test "buy then a few oversells buy sell than a buy" do
    create(:sell_trade, price: 10, quantity: 200, account: @account, security: @security)
    assert_equal 0, @account.gain_losses.sum(:amount)

    create(:sell_trade, price: 10, quantity: 50, account: @account, security: @security)
    create(:sell_trade, price: 10, quantity: 50, account: @account, security: @security)
    assert_equal 2000, @account.lots.sum(:amount)
    assert_equal -200, @account.lots.sum(:quantity)
    create(:trade, price: 10, quantity: 50, account: @account, security: @security)
    assert_equal 1500, @account.lots.sum(:amount)
    assert_equal -150, @account.lots.sum(:quantity)
    create(:sell_trade, price: 10, quantity: 50, account: @account, security: @security)
    assert_equal 0, @account.gain_losses.sum(:amount)
    create(:trade, price: 10, quantity: 50, account: @account, security: @security)
    assert_equal 0, @account.gain_losses.sum(:amount)
  end

  test "random buys and sells" do
    security_2 = create(:security, user: @security.user)
    securities = [@security, security_2]
    (1..20).each do |count|
      create(:trade, account: @account, security: securities[rand(2)], quantity: rand(49) * 2, trade_type: Trade::TYPES[rand(2)], date: Date.today - rand(20))
    end

    assert_equal 0, @account.gain_losses.sum(:amount)
  end
end

