module Photos
  class RemoveService
    include ::Interactor

    delegate :storage_filename, :yandex_token, to: :context

    def call
      client.delete(name: [yandex_token.dir, storage_filename].join('/'))
    rescue ::YandexPhotoStorage::NotFoundError
      false
    end

    private

    def client
      @client ||= ::YandexPhotoStorage::Dav::Client.new(access_token: yandex_token.access_token)
    end
  end
end
