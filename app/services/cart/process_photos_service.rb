# frozen_string_literal: true

module Cart
  class ProcessPhotosService
    def initialize(rubric_id)
      @rubric_id = rubric_id
    end

    def call
      raise 'no block given' unless block_given?

      each_photo do |photo|
        redis.call('SREM', key, photo.id) if yield(photo)
        ids.delete(photo.id.to_s)
      end

      clear_incorrect
    end

    def self.call(rubric_id, &)
      new(rubric_id).call(&)
    end

    private

    delegate :redis, to: 'Rails.application', private: true

    def clear_incorrect
      redis.call('SREM', key, ids.to_a) if ids.any?
    end

    def each_photo(&)
      Photo.
        where(id: ids, rubric_id: @rubric_id).
        each_instance(with_hold: true, &)
    end

    def ids
      @ids ||= redis.call('SMEMBERS', key).to_set
    end

    def key
      @key ||= "cart:photos:#{@rubric_id}"
    end
  end
end
