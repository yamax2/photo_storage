# frozen_string_literal: true

class AddFinishedAtToTracks < ActiveRecord::Migration[6.1]
  def up
    change_table :tracks, bulk: true do |t|
      t.datetime :finished_at
      t.remove :avg_speed
    end
  end

  def down
    change_table :tracks, bulk: true do |t|
      t.remove :finished_at
      t.numeric :avg_speed, default: 0, null: false
    end
  end
end
