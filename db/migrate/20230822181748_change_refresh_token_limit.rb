# frozen_string_literal: true

class ChangeRefreshTokenLimit < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        change_column :yandex_tokens, :refresh_token, :string, limit: 255, null: false
      end

      dir.down do
        change_column :yandex_tokens, :refresh_token, :string, limit: 255, null: false
      end
    end
  end
end
