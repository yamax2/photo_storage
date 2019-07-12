class AddViewsToPhotos < ActiveRecord::Migration[5.2]
  def change
    add_column :photos, :views, :bigint, default: 0, null: false
  end
end
