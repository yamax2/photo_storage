# frozen_string_literal: true

class AddHideCommonStatToRubrics < ActiveRecord::Migration[6.1]
  def change
    add_column :rubrics, :hide_common_stat, :boolean, default: false, null: false
  end
end
