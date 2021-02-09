# frozen_string_literal: true

class AddCountersToRubrics < ActiveRecord::Migration[5.2]
  def change
    change_table :rubrics, bulk: true do |t|
      t.bigint :rubrics_count, default: 0, null: false
      t.bigint :photos_count, default: 0, null: false
    end
  end
end
