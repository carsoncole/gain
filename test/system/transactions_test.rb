require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    @account = create(:account)
    @transaction = create(:transaction, account: @account)
  end

  test "visiting the index" do
    visit account_transactions_url(@account)
    assert_selector "h1", text: "Transactions"
  end

  test "should create transaction" do
    visit account_transactions_url(@account)
    click_on "new-transaction-link"

    fill_in "Amount", with: @transaction.amount
    fill_in "Date", with: @transaction.date
    fill_in "Fee", with: @transaction.fee
    fill_in "Other", with: @transaction.other
    fill_in "Price", with: @transaction.price
    fill_in "Quantity", with: @transaction.quantity
    select "#{@transaction.security.name}", from: "transaction_security_id"
    select @transaction.transaction_type, from: "transaction_transaction_type"
    click_on "Create Transaction"

    assert_text "Transaction was successfully created"
  end

  test "should update Transaction" do
    visit account_transaction_url(@account, @transaction)
    click_on "edit-transaction", match: :first

    fill_in "Amount", with: @transaction.amount
    fill_in "Date", with: @transaction.date
    fill_in "Fee", with: @transaction.fee
    fill_in "Other", with: @transaction.other
    fill_in "Price", with: @transaction.price
    fill_in "Quantity", with: @transaction.quantity
    select "#{@transaction.security.name}", from: "transaction_security_id"
    select @transaction.transaction_type, from: "transaction_transaction_type"
    click_on "Update Transaction"

    assert_text "Transaction was successfully updated"
    click_on "Back"
  end

  test "should destroy Transaction" do
    visit account_transaction_url(@account, @transaction)
    accept_confirm do
      click_on "delete-transaction", match: :first
    end

    assert_text "Transaction was successfully destroyed"
  end
end
