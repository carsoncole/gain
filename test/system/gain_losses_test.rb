require "application_system_test_case"

class GainLossesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    system_test_signin(@user)
    @account = create(:account, user: @user)
    security = create(:security, user: @account.user)
    create_list(:buy_trade, 5, account: @account, security: security, date: Date.today - 2.years)
    create_list(:buy_trade, 3, account: @account, security: security, date: Date.today - 1.month)
    create_list(:sell_trade, 6, account: @account, security: security, quantity: 100, price: 25)
  end


  test "visiting the index" do
    visit account_gain_losses_url(@account)
    assert_selector "h1", text: "Gains and Losses"
  end

  test "visiting schedule d" do
    visit account_gain_losses_url(@account)
    click_link "IRS Schedule D"
    assert_selector "h1", text: "IRS Schedule D"
    assert_selector "h2", text: "Short Term"
    assert_selector "h2", text: "Long Term"
  end

end
