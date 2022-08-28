# frozen_string_literal: true

module Videos
  class MoveOriginalJob
    include Sidekiq::Worker

    def perform(id, temporary_filename)
      video = Photo.find(id)

      MoveOriginalService.new(video, temporary_filename).call
    end
  end
end
