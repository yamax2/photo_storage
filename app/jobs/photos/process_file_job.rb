# frozen_string_literal: true

module Photos
  class ProcessFileJob
    include Sidekiq::Worker

    def perform(photo_id, new_storage_filename)
      photo = Photo.find(photo_id)

      Photos::Process.call!(
        photo: photo,
        storage_filename: new_storage_filename
      )
    end
  end
end
