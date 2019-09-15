module Photos
  class LoadDescriptionJob
    include Sidekiq::Worker
    include Sidekiq::Throttled::Worker

    sidekiq_options queue: :descr
    sidekiq_throttle concurrency: {limit: 1}, threshold: {limit: 1, period: 2.second}

    def perform(photo_id)
      photo = Photo.find(photo_id)

      LoadDescriptionService.call!(photo: photo)
    end
  end
end
