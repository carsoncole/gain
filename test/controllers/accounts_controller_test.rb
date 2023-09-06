require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user = @account.user
  end

  test "should get index" do
    get accounts_url(as: @user)
    assert_response :success
  end

  test "should get new" do
    get new_account_url(as: @user)
    assert_response :success
  end

  test "should get show" do
    get account_url(@account, as: @user)
    assert_response :success
  end

  test "should create account" do
    assert_difference("Account.count") do
      post accounts_url(as: @user), params: { account: { currency_id: @account.currency_id, number: @account.number, title: @account.title } }
    end

    assert_redirected_to accounts_url
  end

  test "should get edit" do
    get edit_account_url(@account, as: @user)
    assert_response :success
  end

  test "should update account" do
    patch account_url(@account, as: @user), params: { account: { currency_id: @account.currency_id, number: @account.number, title: @account.title } }
    assert_redirected_to accounts_url
  end

  test "should destroy account" do
    assert_difference("Account.count", -1) do
      delete account_url(@account, as: @user)
    end

    assert_redirected_to accounts_url
  end
end
