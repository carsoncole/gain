require "application_system_test_case"

class PositionsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @account = create(:account, user: @user)
    system_test_signin(@user)
  end

  test "visiting the index" do
    visit accounts_url
    click_on "account-#{@account.id}-link"
    click_on "Positions"
  end
end
