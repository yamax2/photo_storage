module Photos
  class ProcessFileJob
    include Sidekiq::Worker

    def perform(photo_id)
      photo = Photo.find(photo_id)

      Photos::Process.call!(photo: photo)
    end
  end
end
