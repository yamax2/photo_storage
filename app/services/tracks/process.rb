# frozen_string_literal: true

module Tracks
  class Process
    include ::Interactor::Organizer

    organize LoadInfoService, UploadService
  end
end
