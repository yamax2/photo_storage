class UploadService
  include ::Interactor

  delegate :photo, to: :context

  def call
    context.fail!(message: 'active token not found') unless token_for_upload.present?

    photo.yandex_token = token_for_upload
    photo.generate_storage_filename

    validate_remote_directories
    upload_file
    remove_temp_file

    photo.save!
  end

  private

  def client
    @client ||= ::YandexPhotoStorage::Dav::Client.new(access_token: photo.yandex_token.access_token)
  end

  def remove_temp_file
    FileUtils.rm_f(photo.local_filename)
    photo.local_filename = nil
  end

  def token_for_upload
    @token_for_upload ||= Yandex::Token.where(active: true).order(:id).first
  end

  def upload_file
    client.put(
      file: Rails.root.join('tmp', 'files', photo.local_filename),
      name: photo.yandex_token.dir + '/' + photo.storage_filename
    )
  end

  def validate_directory(path)
    client.propfind(name: path)
  rescue ::YandexPhotoStorage::ApiRequestError => e
    raise if e.code == 404

    client.mkcol(name: path)
  end

  def validate_remote_directories
    dirs = token_for_upload.dir.split('/') + photo.storage_filename.split('/')

    dirs.pop
    dirs.delete_if(&:empty?)

    dirs.each_with_object('') do |dir, path|
      path << '/' << dir

      validate_directory(path)
    end
  end
end
