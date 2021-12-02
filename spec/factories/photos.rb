# frozen_string_literal: true

FactoryBot.define do
  factory :photo do
    sequence(:name) { |n| "photo #{n}" }
    rubric
    sequence(:original_filename) { |n| "file #{n}" }
    content_type { 'image/jpeg' }

    sequence(:md5) { SecureRandom.hex(16).to_s }
    sequence(:sha256) { SecureRandom.hex(32).to_s }

    trait :real do
      md5 { nil }
      sha256 { nil }
    end

    trait :video do
      content_type { 'video/mp4' }
      preview_size { 100 }
      preview_filename { 'test.mp4' }
    end
  end
end
