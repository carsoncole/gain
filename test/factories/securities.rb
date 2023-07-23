FactoryBot.define do
  factory :security do
    name { Faker::Company.name }
    symbol { [*('A'..'Z')].sample(3).join }
    currency
  end
end
