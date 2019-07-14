class AddOrdToRubrics < ActiveRecord::Migration[5.2]
  def change
    add_column :rubrics, :ord, :integer
  end
end
