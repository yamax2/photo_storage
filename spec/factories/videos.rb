# frozen_string_literal: true

FactoryBot.define do
  factory :video do
    sequence(:name) { |n| "video #{n}" }
    rubric

    sequence(:original_filename) { |n| "file #{n}" }
    sequence(:preview_filename) { |n| "file_preview_#{n}.jpg" }
    sequence(:storage_filename) { |n| "file_#{n}.mp4" }

    content_type { 'video/mp4' }

    sequence(:md5) { SecureRandom.hex(16).to_s }
    sequence(:sha256) { SecureRandom.hex(32).to_s }

    width { 3_840 }
    height { 2_160 }
  end
end
