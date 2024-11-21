# frozen_string_literal: true

module Videos
  class StoreService
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def call
      assign_node

      storage_filename = ::StorageFilenameGenerator.call(model, partition: false, prefix: :video)

      model.assign_attributes(
        folder_index: model.yandex_token&.other_folder_index.to_i,
        storage_filename:,
        preview_filename: "#{storage_filename}.jpg",
        video_preview_filename: "#{File.basename(storage_filename, '.*')}.preview.mp4"
      )
    end

    private

    def assign_node
      model.yandex_token_id = ::Yandex::TokenForUploadService.call!(
        resource_size: model.size + model.preview_size + model.video_preview_size
      ).token_id
    end
  end
end
