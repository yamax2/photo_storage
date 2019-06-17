FactoryBot.define do
  factory :'yandex/token' do
    sequence(:user_id) { |n| n * 10 }
    sequence(:login) { |n| "user#{n}@yandex.ru" }
    access_token { 'access_token' }
    valid_till { 10.hours.from_now }
    refresh_token { 'refresh_token' }
    token_type { 'bearer' }

    dir { '/test_photos' }
    other_dir { '/other_test_photos' }
  end
end
