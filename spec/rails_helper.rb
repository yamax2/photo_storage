require 'spec_helper'
require 'strip_attributes/matchers'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'strip_attributes/matchers'
require 'timecop'
require 'webmock/rspec'
require 'vcr'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include StripAttributes::Matchers

  config.use_transactional_fixtures = true

  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

API_APPLICATION_KEY = 'key'.freeze
API_APPLICATION_SECRET = 'secret'.freeze

API_ACCESS_TOKEN = 'access'.freeze
API_REFRESH_TOKEN = 'refresh'.freeze

VCR.configure do |c|
  c.ignore_localhost = true
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock

  c.filter_sensitive_data('<API_SECRET_KEY>') { API_APPLICATION_SECRET }
  c.filter_sensitive_data('<TOKEN>') { API_ACCESS_TOKEN }
  c.filter_sensitive_data('<REFRESH_TOKEN>') { API_REFRESH_TOKEN }

  c.configure_rspec_metadata!
end

YandexPhotoStorage.configure do |config|
  config.api_key = API_APPLICATION_KEY
  config.api_secret = API_APPLICATION_SECRET
end
