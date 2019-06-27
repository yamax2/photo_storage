module Photos
  class Process
    include ::Interactor::Organizer

    organize LoadInfoService, UploadService, MainPhotoService
  end
end
