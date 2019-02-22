FactoryBot.define do
  factory :city do
    name { Faker::Address.city }
    sequence(:domain) { |n| "www#{n.next * 10}" }
  end
end
