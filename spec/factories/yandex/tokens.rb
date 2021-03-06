# frozen_string_literal: true

FactoryBot.define do
  factory :'yandex/token' do
    sequence(:user_id) { |n| n * 10 }
    sequence(:login) { |n| "user#{n}@yandex.ru" }
    access_token { 'access_token' }
    valid_till { 10.hours.from_now }
    refresh_token { 'refresh_token' }

    dir { '/test_photos' }
    other_dir { '/other_test_photos' }

    total_space { 1.gigabyte }
  end
end
