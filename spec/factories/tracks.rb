# frozen_string_literal: true

FactoryBot.define do
  factory :track do
    sequence(:name) { |n| "track #{n}" }
    rubric
  end
end
