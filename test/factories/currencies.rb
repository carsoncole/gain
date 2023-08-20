FactoryBot.define do
  factory :currency do
    user
    name { Faker::Currency.name }
    symbol { Faker::Currency.code }
  end
end
