# frozen_string_literal: true

class MoveFolderIndexesToJson < ActiveRecord::Migration[7.0]
  def up
    add_column :yandex_tokens,
               :folder_indexes,
               :jsonb, default: {photos_folder_index: 0, other_folder_index: 0}, null: false

    unless Rails.env.test?
      execute <<~SQL.squish
        WITH source AS (
          SELECT id,
                jsonb_build_object(
                  'photos_folder_index', photos_folder_index,
                  'other_folder_index', other_folder_index
                ) obj
          FROM yandex_tokens
          GROUP BY id
        )
        UPDATE yandex_tokens
        SET folder_indexes = source.obj
        FROM source
          WHERE yandex_tokens.id = source.id
      SQL
    end

    change_table :yandex_tokens, bulk: true do |t|
      t.remove :photos_folder_index
      t.remove :other_folder_index
    end
  end

  def down
    change_table :yandex_tokens, bulk: true do |t|
      t.integer :photos_folder_index, default: 0, null: false
      t.integer :other_folder_index, default: 0, null: false
    end

    remove_column :yandex_tokens, :folder_indexes
  end
end
