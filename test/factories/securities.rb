FactoryBot.define do
  factory :security do
    user
    name { Faker::Company.name }
    symbol { [*('A'..'Z')].sample(3).join }
    currency
  end
end
