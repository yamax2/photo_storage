# frozen_string_literal: true

module Storable
  extend ActiveSupport::Concern

  included do
    validates :md5, :sha256, presence: true
    validates :md5, length: {is: 32}
    validates :sha256, length: {is: 64}
    validates :sha256, uniqueness: {scope: :md5}

    validates :yandex_token, presence: true, if: :storage_filename
    validate  :upload_status

    scope :uploaded, -> { where.not(storage_filename: nil) }
    scope :pending, -> { where.not(local_filename: nil) }

    before_validation :read_file_attributes, if: :local_file?
    after_commit :remove_file, unless: :persisted?
  end

  def local_file?
    local_filename.present? && File.exist?(tmp_local_filename)
  end

  def tmp_local_filename
    Rails.root.join('tmp', 'files', local_filename)
  end

  private

  def read_file_attributes
    self.md5 ||= Digest::MD5.file(tmp_local_filename).to_s
    self.sha256 ||= Digest::SHA256.file(tmp_local_filename).to_s
  end

  def remove_file
    FileUtils.rm_f(tmp_local_filename) if local_file?
  end

  def upload_status
    return if [storage_filename, local_filename].compact.size == 1

    errors.add(:local_filename, :wrong_value)
  end
end
