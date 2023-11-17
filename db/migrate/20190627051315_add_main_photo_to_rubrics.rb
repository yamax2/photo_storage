# frozen_string_literal: true

class AddMainPhotoToRubrics < ActiveRecord::Migration[5.2]
  def change
    add_reference :rubrics, :main_photo, index: false

    add_index :rubrics, :main_photo_id, where: 'main_photo_id is not null'
    add_foreign_key :rubrics, :photos, name: 'fk_rubrics_main_photo',
                                       on_delete: :nullify,
                                       on_update: :cascade,
                                       column: :main_photo_id
  end
end
