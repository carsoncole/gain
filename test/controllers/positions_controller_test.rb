require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
  end

  test "should get index" do
    get account_positions_url(@account)
    assert_response :success
  end
end
