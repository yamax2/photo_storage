# frozen_string_literal: true

class CreateYandexTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :yandex_tokens do |t|
      # from yandex passport info
      t.string :user_id, null: false, limit: 20
      t.string :login, limit: 255, null: false

      # yandex oauth
      t.string :access_token, limit: 100, null: false
      t.datetime :valid_till, null: false
      t.string :refresh_token, limit: 100, null: false
      t.string :token_type, limit: 20, null: false

      # dirs
      t.string :dir, limit: 255
      t.string :other_dir, limit: 255

      # state
      t.boolean :active, default: false, null: false
      t.bigint  :used_space, null: false, default: 0
      t.bigint  :total_space, null: false, default: 0

      t.timestamps null: false
    end

    add_index :yandex_tokens, :user_id, unique: true
  end
end
