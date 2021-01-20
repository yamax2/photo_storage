# frozen_string_literal: true

class AddLastArchivedAt < ActiveRecord::Migration[6.1]
  def change
    add_column :yandex_tokens, :last_archived_at, :datetime
  end
end
