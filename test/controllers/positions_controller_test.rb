require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user = @account.user
  end

  test "should get index" do
    get account_positions_url(@account, as: @user)
    assert_response :success
  end
end
