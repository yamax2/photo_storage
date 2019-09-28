module Photos
  # when photo's rubric changed from old_rubric to photo.rubric
  # the next step is main_photo_service for photo
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

    # FIXME: duplicates RubricFinder code
    def current_rubric_with_parent_ids
      Rubric.where(<<~SQL).pluck(:id)
        id in (
          WITH RECURSIVE tt AS (
            SELECT id, rubric_id
              FROM #{Rubric.quoted_table_name}
             WHERE id = #{photo.rubric_id}
          UNION ALL
          SELECT rubrics.id, rubrics.rubric_id
            FROM #{Rubric.quoted_table_name} rubrics, tt
              WHERE rubrics.id = tt.rubric_id
          )
          SELECT tt.id FROM tt
        )
      SQL
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
