# frozen_string_literal: true

class AddForeignKeysToTracks < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :tracks, :rubrics, name: 'fk_track_rubrics', on_delete: :restrict, on_update: :cascade
    add_foreign_key :tracks, :yandex_tokens, name: 'fk_tracks_tokens', on_delete: :restrict, on_update: :cascade
  end
end
