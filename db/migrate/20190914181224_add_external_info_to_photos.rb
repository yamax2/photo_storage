class AddExternalInfoToPhotos < ActiveRecord::Migration[5.2]
  def change
    add_column :photos, :external_info, :text
  end
end
