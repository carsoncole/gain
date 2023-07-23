require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    @transaction = transactions(:one)
  end

  test "visiting the index" do
    visit transactions_url
    assert_selector "h1", text: "Transactions"
  end

  test "should create transaction" do
    visit transactions_url
    click_on "New transaction"

    fill_in "Account", with: @transaction.account_id
    fill_in "Amount", with: @transaction.amount
    fill_in "Cash balance", with: @transaction.cash_balance
    fill_in "Date", with: @transaction.date
    fill_in "Fee", with: @transaction.fee
    fill_in "Other", with: @transaction.other
    fill_in "Price", with: @transaction.price
    fill_in "Quantity", with: @transaction.quantity
    fill_in "Security balance", with: @transaction.security_balance
    fill_in "Security", with: @transaction.security_id
    fill_in "Transaction type", with: @transaction.transaction_type
    click_on "Create Transaction"

    assert_text "Transaction was successfully created"
    click_on "Back"
  end

  test "should update Transaction" do
    visit transaction_url(@transaction)
    click_on "Edit this transaction", match: :first

    fill_in "Account", with: @transaction.account_id
    fill_in "Amount", with: @transaction.amount
    fill_in "Cash balance", with: @transaction.cash_balance
    fill_in "Date", with: @transaction.date
    fill_in "Fee", with: @transaction.fee
    fill_in "Other", with: @transaction.other
    fill_in "Price", with: @transaction.price
    fill_in "Quantity", with: @transaction.quantity
    fill_in "Security balance", with: @transaction.security_balance
    fill_in "Security", with: @transaction.security_id
    fill_in "Transaction type", with: @transaction.transaction_type
    click_on "Update Transaction"

    assert_text "Transaction was successfully updated"
    click_on "Back"
  end

  test "should destroy Transaction" do
    visit transaction_url(@transaction)
    click_on "Destroy this transaction", match: :first

    assert_text "Transaction was successfully destroyed"
  end
end
