# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "git@github.com:#{repo}.git" }

gem 'irb', require: false
gem 'pg'
gem 'puma', '>= 4.3'
gem 'rails', '~> 6.0'
gem 'sass-rails', '>= 5.0'
gem 'uglifier', '>= 1.3.0'

gem 'bootsnap', '>= 1.1.0', require: false
gem 'coffee-rails', '>= 4.2'
gem 'jbuilder', '>= 2.5'
gem 'turbolinks', '>= 5'

gem 'bootstrap', '~> 4'
gem 'bootstrap4-datetime-picker-rails'
gem 'font-awesome-rails', '~> 4.7'
gem 'jquery-rails'
gem 'jquery-simplecolorpicker-rails'
gem 'leaflet-rails'
gem 'slim-rails', '>= 3.2'

gem 'draper', '>= 3.1'
gem 'gretel', '>= 3'
gem 'interactor', '>= 3.1'
gem 'kaminari', '>= 1.1'
gem 'postgresql_cursor', '>= 0.6.2'
gem 'ransack', '>= 2.1'
gem 'redis-classy', '>= 2.4'
gem 'redis-mutex', '>= 4'
gem 'russian'
gem 'strip_attributes', '>= 1.8'

gem 'sidekiq', '>= 6'
gem 'sidekiq-cron', '>= 1.1'
gem 'sidekiq-failures', '>= 1'
gem 'sidekiq-throttled', '>= 0.13'

gem 'exifr'
gem 'gpx'
gem 'image_size'
gem 'yandex_client', '>= 0.2'

group :development, :test do
  gem 'byebug'
  gem 'letter_opener'
  gem 'pry'
  gem 'pry-rails'
end

group :test do
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'

  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'

  gem 'capistrano', '>= 3.10', require: false
  gem 'capistrano-rails', '>= 1.4', require: false
  gem 'capistrano-rbenv', require: false
end

group :production do
  gem 'mini_racer', platforms: :ruby
end
