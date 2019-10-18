# frozen_string_literal: true

class AddNullsToPhotosTimestamps < ActiveRecord::Migration[5.2]
  def change
    change_column_null :photos, :original_timestamp, true
  end
end
