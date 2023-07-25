require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
  end

  test "amount calculation with no fees, commissions" do
    transaction = create(:transaction)
    assert_equal 1000, transaction.amount
  end

  test "amount calculation" do
    transaction = create(:transaction, fee: 15, other: 20)
    assert_equal 1035, transaction.amount
  end

end
