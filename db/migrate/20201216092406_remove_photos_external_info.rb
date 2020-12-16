class RemovePhotosExternalInfo < ActiveRecord::Migration[6.1]
  def up
    remove_column :photos, :external_info
  end

  def down
    add_column :photos, :external_info, :text
  end
end
