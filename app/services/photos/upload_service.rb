module Photos
  class UploadService
    include ::Interactor

    delegate :photo, to: :context

    def call
      return if photo.storage_filename.present?

      validate_upload

      @storage_filename = StorageFilenameGenerator.new(photo).call

      create_remote_dirs
      upload_file
      update_photo
    end

    private

    def client
      @client ||= ::YandexPhotoStorage::Dav::Client.new(access_token: token_for_upload.access_token)
    end

    def create_remote_dir(path)
      client.propfind(name: path)
    rescue ::YandexPhotoStorage::ApiRequestError => e
      raise if e.code == 404

      client.mkcol(name: path)
    end

    def create_remote_dirs
      dirs = token_for_upload.dir.split('/') + @storage_filename.split('/')

      dirs.pop
      dirs.delete_if(&:empty?)

      dirs.each_with_object('') do |dir, path|
        path << '/' << dir

        create_remote_dir(path)
      end
    end

    def local_file
      @local_file ||= photo.tmp_local_filename
    end

    def token_for_upload
      @token_for_upload ||= Yandex::Token.where(active: true).order(:id).first
    end

    def upload_file
      client.put(
        file: local_file,
        name: token_for_upload.dir + '/' + @storage_filename,
        size: photo.size,
        md5: photo.md5,
        sha256: photo.sha256
      )
    end

    def validate_upload
      context.fail!(message: 'local file not found') unless photo.local_file?
      context.fail!(message: 'active token not found') unless token_for_upload.present?
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
