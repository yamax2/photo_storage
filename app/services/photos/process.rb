# frozen_string_literal: true

module Photos
  class Process
    include ::Interactor::Organizer

    organize LoadInfoService, UploadService, MainPhotoService, EnqueueLoadDescriptionService
  end
end
