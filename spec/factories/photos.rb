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
      preview_filename { 'test.mp4.jpg' }
      preview_md5 { Digest::MD5.hexdigest(SecureRandom.hex(32)) }
      preview_sha256 { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }

      video_preview_size { 200 }
      video_preview_filename { 'test.preview.mp4' }
      video_preview_md5 { Digest::MD5.hexdigest(SecureRandom.hex(32)) }
      video_preview_sha256 { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
    end
  end
end
