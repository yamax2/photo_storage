# frozen_string_literal: true

class AddUniqAttrsToPhotos < ActiveRecord::Migration[5.2]
  def change
    change_table :photos, bulk: true do |t|
      t.string :md5, limit: 32, null: false
      t.string :sha256, limit: 64, null: false
    end

    add_index :photos, %i[md5 sha256], unique: true, name: 'uq_photos'
  end
end
