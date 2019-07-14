module Rubrics
  class ApplyOrder
    include ::Interactor

    delegate :data, :id, to: :context

    def call
      RedisMutex.with_lock('rubrics', block: 30.seconds, expire: 10.minutes) do
        Rubric.transaction do
          data.each_with_index do |id, index|
            rubric = Rubric.find_by_id(id)
            next unless rubric

            validate_rubric(rubric)
            rubric.update!(ord: index)
          end
        end
      end
    end

    private

    def validate_rubric(rubric)
      return if rubric.rubric_id == id

      context.fail!(message: "wrong parent rubric for #{rubric.id}, expected #{id}")
    end
  end
end
