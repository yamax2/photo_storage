# frozen_string_literal: true

class RubricDecorator < ApplicationDecorator
  delegate_all

  def rubrics_tree
    current_rubric = object
    rubrics = []

    loop do
      rubrics << current_rubric
      current_rubric = current_rubric.rubric

      break if current_rubric.blank?
    end

    rubrics
  end
end
