class RubricDecorator < Draper::Decorator
  delegate_all

  def rubrics_tree
    current_rubric = self.object
    rubrics = []

    loop do
      rubrics << current_rubric
      current_rubric = current_rubric.rubric

      break unless current_rubric.present?
    end

    rubrics
  end
end
