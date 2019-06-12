class CreateRubrics < ActiveRecord::Migration[5.2]
  def change
    create_table :rubrics do |t|
      t.string :name, null: false, limit: 100
      t.text   :description
      t.references :rubric, index: true

      t.timestamps null: false
    end

    add_foreign_key :rubrics, :rubrics, name: 'fk_rubrics', on_delete: :restrict, on_update: :cascade
  end
end
