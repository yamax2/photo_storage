# frozen_string_literal: true

class RubricDecorator < ApplicationDecorator
  delegate_all

  def main_photo
    @main_photo ||= super&.decorate
  end

  def rubric_name
    @rubric_name ||= name.tap do |result|
      result << I18n.t('rubrics.name.rubrics_count_text', rubrics_count: rubrics_count) if rubrics_count.positive?
      result << I18n.t('rubrics.name.photos_count_text', photos_count: photos_count) if photos_count.positive?
    end
  end

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
