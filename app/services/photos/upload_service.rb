module Photos
  class UploadService
    include ::Interactor

    delegate :photo, to: :context

    def call
      return if photo.storage_filename.present?

      context.fail!(message: 'active token not found') unless token_for_upload.present?
      @storage_filename = StorageFilenameGenerator.new(photo).call

      upload_file
      update_photo
    end

    private

    def client
      @client ||= ::YandexPhotoStorage::Dav::Client.new(access_token: token_for_upload.access_token)
    end

    def local_file
      @local_file ||= Rails.root.join('tmp', 'files', photo.local_filename)
    end

    def token_for_upload
      @token_for_upload ||= Yandex::Token.where(active: true).order(:id).first
    end

    def upload_file
      validate_remote_directories

      client.put(
        file: local_file,
        name: token_for_upload.dir + '/' + @storage_filename
      )
    end

    def validate_directory(path)
      client.propfind(name: path)
    rescue ::YandexPhotoStorage::ApiRequestError => e
      raise if e.code == 404

      client.mkcol(name: path)
    end

    def validate_remote_directories
      dirs = token_for_upload.dir.split('/') + @storage_filename.split('/')

      dirs.pop
      dirs.delete_if(&:empty?)

      dirs.each_with_object('') do |dir, path|
        path << '/' << dir

        validate_directory(path)
      end
    end

    def update_photo
      FileUtils.rm_f(local_file)

      photo.assign_attributes(
        storage_filename: @storage_filename,
        yandex_token: token_for_upload,
        local_filename: nil
      )

      photo.save!
    end
  end
end
