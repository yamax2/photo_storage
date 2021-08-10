# frozen_string_literal: true

module Listing
  class ImageProps
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def image_size(size = :thumb, apply_rotation: false)
      actual_size = (@image_size ||= {})[size] ||= calc_image_size(size)

      if turned? && apply_rotation
        actual_size.reverse
      else
        actual_size
      end
    end

    def css_transform
      transforms = []

      transforms += Array.wrap(effects)
      transforms << "rotate(#{rotated * 90}deg)" if rotated

      transforms.join(' ').presence
    end

    def turned?
      rotated.to_i.odd?
    end

    private

    delegate :photo_sizes, to: 'Rails.application.config', private: true
    delegate :width, :height, :rotated, :effects, to: :model, private: true

    def calc_image_size(size)
      thumb_width = thumb_width(size)

      [
        thumb_width,
        height * thumb_width / width
      ].tap do |result|
        if turned?
          result.reverse!

          result[1] = result.first**2 / result.last
        end
      end
    end

    def thumb_width(size)
      result = photo_sizes.fetch(size)
      result = result.call(model) if result.respond_to?(:call)

      # we can scale up only thumbs
      result = width if size != :thumb && result > width

      result
    end
  end
end
