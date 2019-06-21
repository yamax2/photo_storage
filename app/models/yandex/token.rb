module Yandex
  class Token < ApplicationRecord
    self.table_name = 'yandex_tokens'

    validates :valid_till, :used_space, :total_space, presence: true

    validates :user_id, uniqueness: true, presence: true, length: {maximum: 20}
    validates :login, presence: true, length: {maximum: 255}
    validates :token_type, presence: true, length: {maximum: 20}
    validates :access_token, :refresh_token, presence: true, length: {maximum: 100}
    validates :dir, :other_dir, length: {maximum: 255}

    validates :dir, :other_dir, presence: true, if: :active?
    validate :dir_names

    has_many :photos, dependent: :destroy, inverse_of: :yandex_token, foreign_key: :yandex_token_id

    strip_attributes only: %i[dir other_dir]

    # FIXME: move to a decorator
    def proxy_url(other: false)
      actual_dir = other ? other_dir : dir

      "#{Rails.application.routes.default_url_options[:protocol]}://#{Rails.application.config.proxy_domain}." \
        "#{Rails.application.routes.default_url_options[:host]}#{actual_dir}"
    end

    private

    def dir_names
      errors.add(:dir, :wrong_value) unless valid_dir?(dir)
      errors.add(:other_dir, :wrong_value) unless valid_dir?(other_dir)
    end

    def valid_dir?(directory)
      directory.blank? || directory.to_s.starts_with?('/')
    end
  end
end
