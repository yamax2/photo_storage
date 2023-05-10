# frozen_string_literal: true

require 'simplecov' if RSpec.configuration.files_to_run.size > 1
require 'strip_attributes/matchers'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

require 'rspec/rails'
require 'timecop'
require 'webmock/rspec'
require 'vcr'

Dir[Rails.root.join('spec/support/**/*.rb')].each { require _1 }
Dir[Rails.root.join('spec/rspec_helpers/**/*.rb')].each { require _1 }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include StripAttributes::Matchers
  config.include RSpecHelpers::Sidekiq

  config.use_transactional_fixtures = true

  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  config.after do
    Rails.application.redis.call('SCRIPT', :flush)
    Rails.application.redis.call('FLUSHDB')
  end

  config.before { Retry.default_intervals = [0, 0] }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

API_APPLICATION_KEY = 'key'
API_APPLICATION_SECRET = 'secret'

API_ACCESS_TOKEN = 'access'
API_REFRESH_TOKEN = 'refresh'

VCR.configure do |c|
  c.ignore_localhost = true
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock

  c.filter_sensitive_data('<API_SECRET_KEY>') { API_APPLICATION_SECRET }
  c.filter_sensitive_data('<TOKEN>') { API_ACCESS_TOKEN }
  c.filter_sensitive_data('<REFRESH_TOKEN>') { API_REFRESH_TOKEN }

  c.configure_rspec_metadata!

  c.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == 'ASCII-8BIT' ||
      !http_message.body.valid_encoding?
  end
end

YandexClient.configure do |config|
  config.api_key = API_APPLICATION_KEY
  config.api_secret = API_APPLICATION_SECRET
end
