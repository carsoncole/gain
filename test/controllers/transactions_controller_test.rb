require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @transaction = create(:transaction, account: @account)
  end

  test "should get index" do
    get account_transactions_url(@account)
    assert_response :success
  end

  test "should get new" do
    get new_account_transaction_url(@account)
    assert_response :success
  end

  test "should create transaction" do
    assert_difference("Transaction.count") do
      post account_transactions_url @account, params: { account_id: @account.id, transaction: { account_id: @transaction.account_id, amount: @transaction.amount, cash_balance: @transaction.cash_balance, date: @transaction.date, fee: @transaction.fee, other: @transaction.other, price: @transaction.price, quantity: @transaction.quantity, security_balance: @transaction.security_balance, security_id: @transaction.security_id, transaction_type: @transaction.transaction_type } }
    end

    assert_redirected_to account_transactions_url(@account)
  end

  test "should show transaction" do
    get account_transaction_url(@account, @transaction)
    assert_response :success
  end

  test "should get edit" do
    get edit_account_transaction_url(@account, @transaction)
    assert_response :success
  end

  test "should update transaction" do
    patch account_transaction_url(@account, @transaction), params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, cash_balance: @transaction.cash_balance, date: @transaction.date, fee: @transaction.fee, other: @transaction.other, price: @transaction.price, quantity: @transaction.quantity, security_balance: @transaction.security_balance, security_id: @transaction.security_id, transaction_type: @transaction.transaction_type } }
    assert_redirected_to account_transaction_url(@account, @transaction)
  end

  test "should destroy transaction" do
    assert_difference("Transaction.count", -1) do
      delete account_transaction_url(@account, @transaction)
    end

    assert_redirected_to account_transactions_url(@account)
  end
end
