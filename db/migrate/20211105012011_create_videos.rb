# frozen_string_literal: true

class CreateVideos < ActiveRecord::Migration[6.1]
  def change
    create_table :videos do |t|
      t.string     :name, null: false, limit: 512
      t.text       :description
      t.references :rubric, index: true, null: false

      # storage properties
      t.references :yandex_token, null: false, index: true
      t.text       :storage_filename, null: false
      t.text       :preview_filename, null: false

      t.jsonb      :props, default: {}, null: false
      t.point      :lat_long
      t.datetime   :original_timestamp
      t.string     :content_type, limit: 30, null: false
      t.integer    :width, default: 0, null: false
      t.integer    :height, default: 0, null: false
      t.bigint     :views, default: 0, null: false
      t.string     :tz, limit: 50, default: Rails.application.config.time_zone, null: false

      t.string     :md5, limit: 32, null: false
      t.string     :sha256, limit: 64, null: false
      t.string     :original_filename, null: false, limit: 512
      t.bigint     :size, null: false, default: 0

      t.timestamps null: false
    end

    add_index :videos, %i[md5 sha256], unique: true, name: 'uq_videos'

    add_column :rubrics, :videos_count, :bigint, default: 0, null: false
    add_foreign_key :videos, :rubrics, name: 'fk_video_rubrics', on_delete: :restrict, on_update: :cascade
    add_foreign_key :videos, :yandex_tokens, name: 'fk_video_tokens', on_delete: :restrict, on_update: :cascade
  end
end
