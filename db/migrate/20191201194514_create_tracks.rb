class CreateTracks < ActiveRecord::Migration[5.2]
  def change
    create_table :tracks do |t|
      t.string     :name, null: false, limit: 512
      t.references :rubric, index: true, null: false

      t.timestamps null: false
    end

    create_table :track_items do |t|
      t.string     :name, null: false, limit: 512

      t.references :track, index: true, null: false

      # storage properties
      t.references :yandex_token, index: false
      t.text       :storage_filename
      t.text       :local_filename

      t.string     :md5, limit: 32, null: false
      t.string     :sha256, limit: 64, null: false

      # gpx
      t.numeric    :avg_speed, default: 0, null: false
      t.numeric    :duration, default: 0, null: false
      t.numeric    :distance, default: 0, null: false

      t.timestamps null: false
    end

    add_index :track_items, :yandex_token_id, where: 'yandex_token_id is not null'
    add_index :track_items, %i[md5 sha256], unique: true, name: 'uq_track_items'
  end
end
