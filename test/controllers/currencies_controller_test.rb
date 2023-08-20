require "test_helper"

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @currency = create(:currency)
    @user = @currency.user
  end

  test "should get index" do
    get currencies_url(as: @user)
    assert_response :success
  end

  test "should get new" do
    get new_currency_url(as: @user)
    assert_response :success
  end

  test "should create currency" do
    assert_difference("Currency.count") do
      post currencies_url(as: @user), params: { currency: { name: @currency.name, symbol: @currency.symbol } }
    end

    assert_redirected_to currencies_url
  end

  test "should get edit" do
    get edit_currency_url(@currency, as: @user)
    assert_response :success
  end

  test "should update currency" do
    patch currency_url(@currency, as: @user), params: { currency: { name: @currency.name, symbol: @currency.symbol } }
    assert_redirected_to currencies_url
  end

  test "should destroy currency" do
    assert_difference("Currency.count", -1) do
      delete currency_url(@currency, as: @user)
    end

    assert_redirected_to currencies_url
  end
end
