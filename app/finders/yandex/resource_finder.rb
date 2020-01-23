# frozen_string_literal: true

module Yandex
  # finds resources for backup
  class ResourceFinder
    def call
      Yandex::Token.
        order(:id).
        where(photo_condition.or(other_condition)).
        select(
          Yandex::Token.arel_table[Arel.star],
          photo_condition.as('photos_present'),
          other_condition.as('other_present')
        )
    end

    def self.call
      new.call
    end

    private

    def other_condition
      Track.uploaded.where(
        Track.arel_table[:yandex_token_id].eq(Yandex::Token.arel_table[:id])
      ).select(1).arel.exists
    end

    def photo_condition
      Photo.uploaded.where(
        Photo.arel_table[:yandex_token_id].eq(Yandex::Token.arel_table[:id])
      ).select(1).arel.exists
    end
  end
end
