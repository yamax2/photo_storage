class AddExternalInfoToRubrics < ActiveRecord::Migration[5.2]
  def change
    add_column :rubrics, :external_info, :text
  end
end
