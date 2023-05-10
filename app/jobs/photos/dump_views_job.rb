# frozen_string_literal: true

module Photos
  class DumpViewsJob
    include Sidekiq::Worker

    def perform
      Rails.application.redlock.lock!('counters:photo', 5.minutes.in_milliseconds) do
        ::Counters::DumpService.call!(model_klass: ::Photo)
      end
    end
  end
end
