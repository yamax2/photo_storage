class City < ApplicationRecord
  validates :name, presence: true, length: {maximum: 20}
  validates :domain, presence: true, length: {maximum: 15}, uniqueness: true
  validates :in_city_name, :google_verification, :yandex_verification, length: {maximum: 50}

  strip_attributes only: %i[name domain rapid_name],
                   collapse_spaces: true,
                   replace_newlines: true

  before_validation :normalize_domain, if: :domain

  scope :active, -> { where(active: true) }

  private

  def normalize_domain
    self.domain = domain.downcase
  end
end
