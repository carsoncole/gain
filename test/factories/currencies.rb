FactoryBot.define do
  factory :currency do
    name { Faker::Currency.name }
    symbol { Faker::Currency.code }
  end
end
