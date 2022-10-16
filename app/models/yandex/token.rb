# frozen_string_literal: true

module Yandex
  # TODO: rename to Node
  class Token < ApplicationRecord
    self.table_name = 'yandex_tokens'

    store_accessor :folder_indexes,
                   :photos_folder_index,
                   :other_folder_index,
                   :photos_folder_archive_from,
                   :other_folder_archive_from

    validates :valid_till, :used_space, :total_space, presence: true
    validates :user_id, uniqueness: true, presence: true, length: {maximum: 20}
    validates :login, presence: true, length: {maximum: 255}
    validates :access_token, :refresh_token, presence: true, length: {maximum: 100}
    validates :dir, :other_dir, length: {maximum: 255}

    validates :photos_folder_index,
              :other_folder_index,
              :photos_folder_archive_from,
              :other_folder_archive_from,
              presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}

    validates :dir, :other_dir, presence: true, if: :active?
    validate :dir_names

    has_many :photos, dependent: :destroy, inverse_of: :yandex_token, foreign_key: :yandex_token_id
    has_many :tracks, dependent: :destroy, inverse_of: :yandex_token, foreign_key: :yandex_token_id

    strip_attributes only: %i[dir other_dir]

    scope :active, -> { where(active: true).order(:id) }

    ransacker(:free_space) { Arel.sql('total_space - used_space') }
    ransacker(:last_upload_at) { Arel.sql('last_upload_at') }

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
