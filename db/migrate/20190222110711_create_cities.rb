class CreateCities < ActiveRecord::Migration[5.2]
  def change
    create_table :cities do |t|
      t.string  :name, limit: 20, null: false
      t.string  :domain, limit: 15, null: false
      t.boolean :active, default: true, null: false

      t.string  :in_city_name, limit: 50

      t.string  :google_verification, limit: 50
      t.string  :yandex_verification, limit: 50

      t.timestamps null: false
    end

    add_index :cities, :domain, unique: true
  end
end
