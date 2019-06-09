module Yandex
  class Token < ApplicationRecord
    self.table_name = 'yandex_tokens'

    validates :valid_till, :used_space, :total_space, presence: true

    validates :user_id, uniqueness: true, presence: true, length: {maximum: 20}
    validates :login, presence: true, length: {maximum: 255}
    validates :token_type, presence: true, length: {maximum: 20}
    validates :access_token, :refresh_token, presence: true, length: {maximum: 100}
    validates :dir, :other_dir, length: {maximum: 255}
  end
end
