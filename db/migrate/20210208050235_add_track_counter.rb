# frozen_string_literal: true

class AddTrackCounter < ActiveRecord::Migration[6.1]
  def change
    add_column :rubrics, :tracks_count, :bigint, default: 0, null: false
  end
end
