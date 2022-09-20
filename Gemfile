# frozen_string_literal: true

source 'https://rubygems.org'

gem 'pg'
gem 'puma', '>= 4.3'
gem 'rails', '~> 7.0'
gem 'sass-rails', '>= 5.0'
gem 'sprockets-rails', '>= 3.4'
gem 'uglifier', '>= 1.3.0'

gem 'bootsnap', '>= 1.1.0', require: false
gem 'coffee-rails', '>= 4.2'
gem 'jbuilder', '>= 2.5'
gem 'turbolinks', '>= 5'

gem 'bootstrap', '~> 4'
gem 'bootstrap4-datetime-picker-rails'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'jquery-simplecolorpicker-rails'
gem 'leaflet-rails', '< 1.8.0' # https://github.com/Leaflet/Leaflet.markercluster/issues/1065
gem 'slim-rails', '>= 3.2'

gem 'draper', '>= 3.1'
gem 'gretel', '>= 3'
gem 'interactor', '>= 3.1'
gem 'kaminari', '>= 1.1'
gem 'postgresql_cursor', '>= 0.6.2'
gem 'rails_semantic_logger'
gem 'ransack', '>= 2.1'
gem 'redis-classy', '>= 2.4'
gem 'redis-mutex', '>= 4'
gem 'strip_attributes', '>= 1.8'

gem 'sidekiq', '>= 6'
gem 'sidekiq-cron', '>= 1.1'
gem 'sidekiq-failures', '>= 1'
gem 'sidekiq-throttled', '>= 0.13'

gem 'exifr'
gem 'gpx', github: 'dougfales/gpx'
gem 'image_size'
gem 'yandex_client'

group :development, :test do
  gem 'byebug'
  gem 'letter_opener'
  gem 'pry'
  gem 'pry-rails'
end

group :test do
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'

  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

  gem 'rspec-rails', '>= 4.1.0'
end

group :development do
  gem 'listen'

  gem 'capistrano', '>= 3.10', require: false
  gem 'capistrano-rails', '>= 1.4', require: false
  gem 'capistrano-rbenv', require: false
end
