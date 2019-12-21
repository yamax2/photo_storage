# frozen_string_literal: true

module Photos
  # when photo's rubric changed from old_rubric to photo.rubric
  class ChangeMainPhotoService
    include ::Interactor

    delegate :photo, to: :context

    def call
      Rubric.transaction do
        Rubric.
          where(main_photo: photo).
          where.not(id: current_rubric_with_parent_ids).
          each_instance(with_lock: true) do |rubric|
          rubric.update!(main_photo_id: first_photo_id(rubric))
        end
      end
    end

    private

    def current_rubric_with_parent_ids
      Rubrics::ParentsFinder.call(photo.rubric_id).pluck(:id)
    end

    def first_photo_id(rubric)
      Photo.connection.execute(<<~SQL).first&.fetch('id')
        WITH RECURSIVE tt AS (
          SELECT id, rubric_id, 0 lv
            FROM #{Rubric.quoted_table_name} rubrics
           WHERE id = #{rubric.id}
          UNION ALL
          SELECT rubrics.id, rubrics.rubric_id, tt.lv + 1
          FROM tt, rubrics
          WHERE rubrics.rubric_id = tt.id
        )
        SELECT photos.id
          FROM tt, #{Photo.quoted_table_name} photos
          WHERE photos.rubric_id = tt.id
            ORDER BY tt.lv, photos.id
            LIMIT 1
      SQL
    end
  end
end
