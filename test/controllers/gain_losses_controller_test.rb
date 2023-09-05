require "test_helper"

class GainLossesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user = @account.user
    @security = create(:security, user: @user)
    @trade = create(:trade, account: @account, security: @security)
  end

  test "should get index" do
    get account_gain_losses_url(@account, as: @user)
    assert_response :success
  end

  test "should get schedule d" do
    get account_schedule_d_url(@account, as: @user)
    assert_response :success
  end

  test "should get schedule d for a set year" do
    get account_schedule_d_url(@account, params: { year: true }, as: @user)
    assert_response :success
  end
end
