require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
  end

  test "quantity sign" do
    transaction = build(:transaction, transaction_type: 'Sell')
    assert_equal 100, transaction.quantity
    transaction.valid?
    assert_equal -100, transaction.quantity

    transaction.quantity = transaction.quantity = -200
    transaction.valid?
    assert_equal -200, transaction.quantity
  end

  test "amount calculation with no fees, commissions" do
    transaction = create(:transaction)
    assert_equal 1000, transaction.amount
  end

  test "amount calculationd" do
    transaction = create(:transaction, fee: 15, other: 20)
    assert_equal 1035, transaction.amount
  end

  test "security balance" do
    security = create(:security)

    transaction = create(:transaction, security: security)
    assert_equal 100, transaction.security_balance

    transaction = create(:transaction, quantity: 150, security: security)
    assert_equal 250, transaction.security_balance

    transaction = create(:transaction, quantity: 25, security: security)
    assert_equal 275, transaction.security_balance
  end
end
