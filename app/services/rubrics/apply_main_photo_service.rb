# frozen_string_literal: true

module Rubrics
  class ApplyMainPhotoService
    include ::Interactor

    delegate :photo, :rubric, to: :context

    def call
      validate_photo

      Rubric.transaction do
        rubrics_to_update.each_instance(with_lock: true) do |rubric|
          rubric.update!(main_photo_id: photo.id)
        end
      end
    end

    private

    def rubrics_to_update
      return @rubrics_to_update if defined?(@rubrics_to_update)

      relation = ParentsFinder.call(rubric.id)
      table = Rubric.arel_table

      @rubrics_to_update = relation.where(table[:id].eq(rubric.id).or(table[:main_photo_id].eq(nil)))
    end

    def validate_photo
      context.fail!(message: "#{photo.id} does not belong to rubric #{rubric.id}") unless photo.rubric_id == rubric.id
    end
  end
end
