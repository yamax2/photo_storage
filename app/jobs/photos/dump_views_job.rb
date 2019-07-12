module Photos
  class DumpViewsJob
    include Sidekiq::Worker

    def perform
      RedisMutex.with_lock('counters:photo', block: 5.minutes, expire: 30.minutes) do
        ::Counters::DumpService.call!(model_klass: ::Photo)
      end
    end
  end
end
