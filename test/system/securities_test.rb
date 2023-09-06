require "application_system_test_case"

class SecuritiesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @security = create(:security, user: @user)
    @currency = create(:currency, user: @user)
    system_test_signin(@security.user)
  end

  test "visiting the index" do
    visit securities_url
    assert_selector "h1", text: "Securities"
  end

  test "should create security" do
    visit securities_url
    click_on "new-security-link"
    assert_selector "h1", text: 'New security'

    fill_in "Name", with: @security.name
    fill_in "Symbol", with: @security.symbol
    select @currency.name, from: 'currency-selection'
    click_on "Create Security"

    assert_text "Security was successfully created"
    assert_selector "h1", text: 'Securities'
  end

  test "should update Security" do
    visit securities_url(@security)
    click_on "edit-security-#{@security.id}", match: :first
    assert_selector "h1", text: 'Editing security'

    fill_in "Name", with: @security.name
    click_on "Update Security"

    assert_text "Security was successfully updated"
    assert_selector "h1", text: 'Securities'
  end

  test "should destroy Security" do
    visit securities_url(@security)
    accept_confirm do
      click_on "delete-security-#{@security.id}", match: :first
    end
    assert_text "Security was successfully destroyed"
    assert_selector "h1", text: 'Securities'
  end
end
