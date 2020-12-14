# frozen_string_literal: true

class AddPropsToPhotos < ActiveRecord::Migration[6.0]
  def change
    add_column :photos, :props, :jsonb, default: {}, null: false
  end
end
