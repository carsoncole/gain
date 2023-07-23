FactoryBot.define do
  factory :account do
    title { Faker::Name.first_name }
    number { rand(100000) }
    currency
  end
end
