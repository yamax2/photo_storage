FactoryBot.define do
  factory :photo do
    sequence(:name) { |n| "photo #{n}" }
    rubric
    sequence(:original_filename) { |n| "file #{n}" }
    content_type { 'image/jpeg' }
    association :yandex_token, factory: :'yandex/token'
  end
end
