FactoryBot.define do
  factory :transaction do
    date { "MyString" }
    account { nil }
    security { nil }
    price { "9.99" }
    quantity { "9.99" }
    fee { "9.99" }
    other { "9.99" }
    amount { "9.99" }
    security_balance { "9.99" }
    cash_balance { "9.99" }
    transaction_type { "MyString" }
  end
end
