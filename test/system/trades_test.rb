require "application_system_test_case"

class TradesTest < ApplicationSystemTestCase
  setup do
    @account = create(:account)
    @trade = create(:trade, account: @account)
    system_test_signin(@account.user)
  end

  test "visiting the index" do
    visit account_trades_url(@account)
    assert_selector "h1", text: "Trades"
    has_table? 'trades-tables'
  end

  test "should create trade" do
    visit account_trades_url(@account)
    click_on "new-trade-link"

    fill_in "Amount", with: @trade.amount
    fill_in "Date", with: @trade.date
    fill_in "Fee", with: @trade.fee
    fill_in "Other", with: @trade.other
    fill_in "Price", with: @trade.price
    fill_in "Quantity", with: @trade.quantity
    select "#{@trade.security.name}", from: "trade_security_id"
    select @trade.trade_type, from: "trade_trade_type"
    click_on "Create Trade", match: :first

    assert_text "Trade was successfully created"
    assert_selector "h1", text: "Buy"
  end

  test "invalid trade" do
    visit account_trades_url(@account)
    click_on "new-trade-link"
    click_on "Create Trade", match: :first

    within "#error_explanation" do
      assert_text "2 errors prohibited this trade from being saved"
      assert_text "Price can't be blank"
      assert_text "Quantity can't be blank"
    end

  end

  test "should update Trade" do
    visit account_trade_url(@account, @trade)
    click_on "edit-trade", match: :first
    assert_selector "h1", text: "Editing trade"

    fill_in "Amount", with: @trade.amount
    fill_in "Date", with: @trade.date
    fill_in "Fee", with: @trade.fee
    fill_in "Other", with: @trade.other
    fill_in "Price", with: @trade.price
    fill_in "Quantity", with: @trade.quantity
    select "#{@trade.security.name}", from: "trade_security_id"
    select @trade.trade_type, from: "trade_trade_type"
    click_on "Update Trade", match: :first

    assert_text "Trade was successfully updated"
  end

  test "should destroy Trade" do
    visit account_trade_url(@account, @trade)
    accept_confirm do
      click_on "delete-trade", match: :first
    end

    assert_text "Trade was successfully destroyed"
    assert_selector "h1", text: "Trades"
  end
end
