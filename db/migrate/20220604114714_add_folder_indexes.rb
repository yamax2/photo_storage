# frozen_string_literal: true

class AddFolderIndexes < ActiveRecord::Migration[7.0]
  def change
    change_table :yandex_tokens, bulk: true do |t|
      t.integer :photos_folder_index, default: 0, null: false
      t.integer :other_folder_index, default: 0, null: false
    end

    add_column :photos, :folder_index, :integer, default: 0, null: false
    add_column :tracks, :folder_index, :integer, default: 0, null: false
  end
end
