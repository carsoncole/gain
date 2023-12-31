require "test_helper"

class LotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @trade = create(:trade, account: @account)
    @user = @account.user
  end

  test "should get index" do
    get account_lots_url(@account, as: @user)
    assert_response :success
  end
end
