require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @currency = create(:currency, user: @user)
    @account = create(:account, user: @user)
    system_test_signin(@user)
  end

  test "visiting the index" do
    visit accounts_url
    assert has_table? "accounts-table"
    assert_selector "h1", text: "Accounts"
  end

  test "should visit account" do
    click_on 'settings-link'
    click_on "account-#{@account.id}-link"
    within "#main-navbar" do
      assert_text @account.title
    end
  end

  test "should create account" do
    visit accounts_url
    click_on "new-account-link"

    fill_in "Title", with: @account.title
    fill_in "Number", with: @account.number
    select @currency.name, from: 'currency-selection'
    click_on "Create Account"

    assert_text "Account was successfully created"
    assert_selector "h1", text: "Accounts"
  end

  test "should update Account" do
    visit accounts_url
    click_on "edit-account-#{@account.id}", match: :first

    fill_in "Title", with: @account.title
    fill_in "Number", with: @account.number
    select @currency.name, from: 'currency-selection'
    click_on "Update Account"

    assert_text "Account was successfully updated"
  end

  test "should destroy Account" do
    visit accounts_url

    accept_confirm do
      click_on "delete-account-#{@account.id}", match: :first
    end

    assert_text "Account was successfully destroyed"
    assert_selector "h1", text: "Accounts"
  end
end
