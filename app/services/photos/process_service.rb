module Photos
  class ProcessService
    include ::Interactor::Organizer

    organize LoadInfoService, UploadService
  end
end
