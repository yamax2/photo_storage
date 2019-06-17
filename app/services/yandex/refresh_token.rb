module Yandex
  class RefreshToken
    include ::Interactor::Organizer

    organize RefreshTokenService, RefreshQuotaService
  end
end
