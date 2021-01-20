# frozen_string_literal: true

class RemoveTokenType < ActiveRecord::Migration[6.1]
  def up
    remove_column :yandex_tokens, :token_type
  end

  def down
    add_column :yandex_tokens, :token_type, :string, limit: 20, null: false
  end
end
