require "test_helper"

class SecuritiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @security = create(:security)
    @user = @security.user
  end

  test "should get index" do
    get securities_url(as: @user)
    assert_response :success
  end

  test "should get new" do
    get new_security_url(as: @user)
    assert_response :success
  end

  test "should create security" do
    assert_difference("Security.count") do
      post securities_url(as: @user), params: { security: { name: @security.name, symbol: @security.symbol, currency_id: @security.currency_id } }
    end

    assert_redirected_to securities_url
  end

  test "should get edit" do
    get edit_security_url(@security, as: @user)
    assert_response :success
  end

  test "should update security" do
    patch security_url(@security, as: @user), params: { security: { name: @security.name } }
    assert_redirected_to securities_url
  end

  test "should destroy security" do
    assert_difference("Security.count", -1) do
      delete security_url(@security, as: @user)
    end

    assert_redirected_to securities_url
  end
end
