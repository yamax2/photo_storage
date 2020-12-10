# frozen_string_literal: true

SimpleCov.start 'rails' do
  minimum_coverage 95

  add_filter 'app/helpers/application_helper.rb'
  add_filter 'app/models/application_record.rb'
end
