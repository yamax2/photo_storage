# frozen_string_literal: true

module Photos
  class ChangeMainPhoto
    include ::Interactor::Organizer

    organize ChangeMainPhotoService, MainPhotoService
  end
end
