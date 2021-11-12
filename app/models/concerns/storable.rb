# frozen_string_literal: true

module Storable
  extend ActiveSupport::Concern

  included do
    validates :original_filename, presence: true, length: {maximum: 512}
    validates :size, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}

    validates :md5, :sha256, presence: true
    validates :md5, length: {is: 32}
    validates :sha256, length: {is: 64}
    validates :sha256, uniqueness: {scope: :md5}
  end
end
