require "application_system_test_case"

class CurrenciesTest < ApplicationSystemTestCase
  setup do
    @currency = create(:currency)
    system_test_signin(@currency.user)
  end

  test "visiting the index" do
    visit currencies_url
    assert_selector "h1", text: "Currencies"
  end

  test "should create currency" do
    visit currencies_url
    click_on "new-currency-link"

    fill_in "Name", with: @currency.name
    fill_in "Symbol", with: @currency.symbol
    click_on "Create Currency"

    assert_text "Currency was successfully created"
    assert_selector "h1", text: 'Currencies'
  end

  test "should update Currency" do
    visit currencies_url
    click_on "edit-currency-#{@currency.id}", match: :first

    fill_in "Name", with: @currency.name
    fill_in "Symbol", with: @currency.symbol
    click_on "Update Currency"

    assert_text "Currency was successfully updated"
    assert_selector "h1", text: 'Currencies'
  end

  test "should destroy Currency" do
    visit currencies_url

    accept_confirm do
      click_on "delete-currency-#{@currency.id}", match: :first
    end

    assert_text "Currency was successfully destroyed"
    assert_selector "h1", text: 'Currencies'
  end
end
