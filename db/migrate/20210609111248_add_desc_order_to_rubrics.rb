# frozen_string_literal: true

class AddDescOrderToRubrics < ActiveRecord::Migration[6.1]
  def change
    add_column :rubrics, :desc_order, :boolean, default: false, null: false
  end
end
