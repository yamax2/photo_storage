class AddCountersToRubrics < ActiveRecord::Migration[5.2]
  def change
    add_column :rubrics, :rubrics_count, :bigint, default: 0, null: false
    add_column :rubrics, :photos_count, :bigint, default: 0, null: false
  end
end
