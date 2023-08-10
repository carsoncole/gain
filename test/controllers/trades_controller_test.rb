require "test_helper"

class TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @trade = create(:trade, account: @account)
  end

  test "should get index" do
    get account_trades_url(@account)
    assert_response :success
  end

  test "should get new" do
    get new_account_trade_url(@account)
    assert_response :success
  end

  test "should create trade" do
    assert_difference("Trade.count") do
      post account_trades_url @account, params: { account_id: @account.id, trade: { account_id: @trade.account_id, amount: @trade.amount, date: @trade.date, fee: @trade.fee, other: @trade.other, price: @trade.price, quantity: @trade.quantity, quantity_balance: @trade.quantity_balance, security_id: @trade.security_id, trade_type: @trade.trade_type } }
    end

    assert_redirected_to account_trades_url(@account)
  end

  test "should show trade" do
    get account_trade_url(@account, @trade)
    assert_response :success
  end

  test "should get edit" do
    get edit_account_trade_url(@account, @trade)
    assert_response :success
  end

  test "should update trade" do
    patch account_trade_url(@account, @trade), params: { trade: { account_id: @trade.account_id, amount: @trade.amount, date: @trade.date, fee: @trade.fee, other: @trade.other, price: @trade.price, quantity: @trade.quantity, quantity_balance: @trade.quantity_balance, security_id: @trade.security_id, trade_type: @trade.trade_type } }
    assert_redirected_to account_trades_url(@account)
  end

  test "should destroy trade" do
    assert_difference("Trade.count", -1) do
      delete account_trade_url(@account, @trade)
    end

    assert_redirected_to account_trades_url(@account)
  end
end
