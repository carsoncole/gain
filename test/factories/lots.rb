FactoryBot.define do
  factory :lot do
    account_id { nil }
    security_id { nil }
    trade_id { 1 }
    quantity { "9.99" }
  end
end
