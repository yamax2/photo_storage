module Yandex
  class RefreshQuotaService
    include ::Interactor

    delegate :token, to: :context

    def call
      response = YandexPhotoStorage::Dav::Client.
        new(access_token: token.access_token).
        propfind(name: '/', quota: true).
        fetch('/')

      token.update_attributes!(
        used_space: response.fetch(:'quota-used-bytes'),
        total_space: response.fetch(:'quota-available-bytes')
      )
    end
  end
end
