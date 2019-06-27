class AddMainPhotoToRubrics < ActiveRecord::Migration[5.2]
  def change
    change_table :rubrics do |t|
      t.references :main_photo, references: :photos, index: false
    end

    add_index :rubrics, :main_photo_id, where: 'main_photo_id is not null'
    add_foreign_key :rubrics, :photos, name: 'fk_rubrics_main_photo',
                                       on_delete: :nullify,
                                       on_update: :cascade,
                                       column: :main_photo_id
  end
end
