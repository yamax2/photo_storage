class CreateTracks < ActiveRecord::Migration[5.2]
  def change
    create_table :tracks do |t|
      t.string     :name, null: false, limit: 512

      t.references :rubric, index: true, null: false

      # storage properties
      t.references :yandex_token, index: false
      t.text       :storage_filename
      t.text       :local_filename

      t.string     :md5, limit: 32, null: false
      t.string     :sha256, limit: 64, null: false
      t.string     :original_filename, null: false, limit: 512
      t.bigint     :size, null: false, default: 0

      # gpx
      t.numeric    :avg_speed, default: 0, null: false
      t.numeric    :duration, default: 0, null: false
      t.numeric    :distance, default: 0, null: false
      t.datetime   :started_at
      t.point      :bounds, array: true, default: [], null: false

      # other
      t.text       :color, null: false, default: 'red'
      t.text       :external_info

      t.timestamps null: false
    end

    add_index :tracks, :yandex_token_id, where: 'yandex_token_id is not null'
    add_index :tracks, %i[md5 sha256], unique: true, name: 'uq_tracks'
  end
end
