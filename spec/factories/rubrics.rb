FactoryBot.define do
  factory :rubric do
    sequence(:name) { |n| "test rubric #{n}" }
  end
end
