# frozen_string_literal: true

class AddUniqAttrsToPhotos < ActiveRecord::Migration[5.2]
  def change
    add_column :photos, :md5, :string, limit: 32, null: false
    add_column :photos, :sha256, :string, limit: 64, null: false

    add_index :photos, %i[md5 sha256], unique: true, name: 'uq_photos'
  end
end
