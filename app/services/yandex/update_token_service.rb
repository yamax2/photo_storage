module Yandex
  class UpdateTokenService
    include ::Interactor::Organizer

    organize RefreshTokenService, RefreshQuotaService
  end
end
