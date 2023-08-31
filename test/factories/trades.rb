FactoryBot.define do
  factory :trade do
    date { Date.today }
    account
    security
    price { "10" }
    quantity { "100" }
    trade_type { Trade::TYPES.first }

    factory :sell_trade do
      trade_type { 'Sell' }
    end

    factory :buy_trade do
      trade_type { 'Buy' }
    end

    factory :split_trade do
      trade_type { 'Split' }
      price { nil }
      quantity { nil }
      split_new_shares { 1000 }
    end

    factory :conversion_trade do
      trade_type { 'Conversion' }
      price { nil }
      quantity { nil }
    end
  end
end
