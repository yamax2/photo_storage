class AddTzToPhotos < ActiveRecord::Migration[5.2]
  def change
    add_column :photos, :tz, :string, default: Rails.application.config.time_zone, null: false, limit: 50
  end
end
