require "application_system_test_case"

class PositionsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @account = create(:account, user: @user)
    @trade_1 = create(:buy_trade, account: @account)
    @trade_2 = create(:buy_trade, account: @account, quantity: 25)
    @trade_3 = create(:buy_trade, account: @account, quantity: 100)
    system_test_signin(@user)
  end

  test "visiting the index" do
    visit accounts_url
    click_on "account-#{@account.id}-link"
    click_on "Positions"
    assert_selector "h1", text: "Positions"
    assert_equal 4, find_by_id('positions-table').all('tr').size
    assert @trade_1.security.name, page.find_by_id("security-#{@trade_1.security_id}").value
  end
end
