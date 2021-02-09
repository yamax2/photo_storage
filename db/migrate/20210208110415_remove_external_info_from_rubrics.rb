# frozen_string_literal: true

class RemoveExternalInfoFromRubrics < ActiveRecord::Migration[6.1]
  def up
    remove_column :rubrics, :external_info
  end

  def down
    add_column :rubrics, :external_info, :text
  end
end
