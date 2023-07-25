FactoryBot.define do
  factory :transaction do
    date { Date.today }
    account
    security
    price { "10" }
    quantity { "100" }
    transaction_type { Transaction::TYPES.first }
  end
end
