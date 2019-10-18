# frozen_string_literal: true

class CreatePhotos < ActiveRecord::Migration[5.2]
  def change
    create_table :photos do |t|
      # common info
      t.string     :name, null: false, limit: 512
      t.text       :description
      t.references :rubric, index: true, null: false

      # storage properties
      t.references :yandex_token, index: false
      t.text       :storage_filename
      t.text       :local_filename

      # photo properties
      t.jsonb      :exif
      t.point      :lat_long
      t.string     :original_filename, null: false, limit: 512
      t.datetime   :original_timestamp, null: false
      t.bigint     :size, null: false, default: 0
      t.string     :content_type, null: false, limit: 30

      # size
      t.integer    :width, null: false, default: 0
      t.integer    :height, null: false, default: 0

      t.timestamps null: false
    end

    add_index :photos, :yandex_token_id, where: 'yandex_token_id is not null'

    add_foreign_key :photos, :rubrics, name: 'fk_photo_rubrics', on_delete: :restrict, on_update: :cascade
    add_foreign_key :photos, :yandex_tokens, name: 'fk_photo_tokens', on_delete: :restrict, on_update: :cascade
  end
end
