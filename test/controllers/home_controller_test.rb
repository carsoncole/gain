require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    @user = create(:user)
    get root_url(as: @user)
    assert_response :success
  end
end
