require "test_helper"

class TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @trade = create(:trade, account: @account)
    @security = @trade.security
    @user = @account.user
    @security_2 = create(:security, user: @user)
  end

  test "should get index" do
    get account_trades_url(@account, as: @user)
    assert_response :success
  end

  test "should get index with all trades" do
    get account_trades_url(@account, params: { all: true}, as: @user)
    assert_response :success
  end

  test "should get new" do
    get new_account_trade_url(@account, as: @user)
    assert_response :success
  end

  test "should create trade" do
    assert_difference("Trade.count") do
      post account_trades_url @account, as: @user, params: { account_id: @account.id, trade: { account_id: @trade.account_id, amount: @trade.amount, date: @trade.date, fee: @trade.fee, other: @trade.other, price: @trade.price, quantity: @trade.quantity, security_id: @trade.security_id, trade_type: @trade.trade_type } }
    end

    assert_redirected_to account_trades_url(@account)
  end

  test "should create trade then conversion" do
    assert_difference("Trade.count", 2) do
      post account_trades_url @account, as: @user, params: { account_id: @account.id, trade: { account_id: @trade.account_id, date: @trade.date, security_id: @trade.security_id, conversion_to_quantity: 100, conversion_from_quantity: 100, conversion_to_security_id: @security_2, trade_type: 'Conversion' } }
    end

    assert_redirected_to account_trades_url(@account)
  end

  test "should create trade then split" do
    assert_difference("Trade.count", 2) do
      post account_trades_url @account, as: @user, params: { account_id: @account.id, trade: { account_id: @trade.account_id, date: @trade.date, split_new_shares: 500, security_id: @trade.security_id, trade_type: 'Split' } }
    end

    assert_redirected_to account_trades_url(@account)
  end

  test "should show trade" do
    get account_trade_url(@account, @trade, as: @user)
    assert_response :success
  end

  test "should get edit" do
    get edit_account_trade_url(@account, @trade, as: @user)
    assert_response :success
  end

  test "should update trade" do
    patch account_trade_url(@account, @trade, as: @user), params: { trade: { account_id: @trade.account_id, amount: @trade.amount, date: @trade.date, fee: @trade.fee, other: @trade.other, price: @trade.price, quantity: @trade.quantity, quantity_balance: @trade.quantity_balance, security_id: @trade.security_id, trade_type: @trade.trade_type } }
    assert_redirected_to account_trades_url(@account)
  end

  test "should destroy trade" do
    assert_difference("Trade.count", -1) do
      delete account_trade_url(@account, @trade, as: @user)
    end

    assert_redirected_to account_trades_url(@account)
  end
end
