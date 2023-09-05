require "application_system_test_case"

class PositionsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @account = create(:account, user: @user)
    @trade_1 = create(:buy_trade, account: @account, date: Date.today - 1.year)
    @trade_2 = create(:buy_trade, account: @account, quantity: 25, date: Date.today - 6.months)
    @trade_3 = create(:buy_trade, account: @account, quantity: 100)
    system_test_signin(@user)
  end

  test "visiting the index" do
    visit accounts_url
    click_on "account-#{@account.id}-link"
    click_on "Positions"
    assert has_table? "positions-table"
    assert_selector "h1", text: "Positions"
  end

  test "date selection should include all available years" do
    visit account_positions_url(@account)
    assert has_select? "filter_date_1i"
    assert has_content? (Date.today-1.year).year
    assert has_content? (Date.today).year

    @trade_1.destroy
    visit account_positions_url(@account)
    assert has_no_content? (Date.today-1.year).year
  end

  test "date filtering" do
    visit account_positions_url(@account)
    assert_equal 4, find_by_id('positions-table').all('tr').size
    assert @trade_1.security.name, page.find_by_id("security-#{@trade_1.security_id}").value
    select((Date.today - 11.months).year, :from => 'filter[date(1i)]')
    click_on 'filter-button'
    sleep 0.5
    assert_equal 2, find_by_id('positions-table').all('tr').size
  end
end
