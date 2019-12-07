# frozen_string_literal: true

FactoryBot.define do
  factory :track do
    sequence(:name) { |n| "track item #{n}" }
    sequence(:md5) { SecureRandom.hex(16).to_s }
    sequence(:sha256) { SecureRandom.hex(32).to_s }
    rubric

    trait :real do
      md5 { nil }
      sha256 { nil }
    end
  end
end
