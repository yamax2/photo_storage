# frozen_string_literal: true

module Listing
  class Item
    DEFAULT_SIZE = [480, 360].freeze
    COLUMNS = %w[
      id
      name
      yandex_token
      yandex_token_id
      storage_filename
      content_type
      width
      height
      lat_long
      props
      rubric_id
      model_type
      photos_count
      rubrics_count
    ].freeze
    private_constant :DEFAULT_SIZE

    (COLUMNS - %w[name]).each do |attr|
      define_method(attr) { @values.fetch(attr) }
    end

    def initialize(attrs = {})
      @values = attrs.with_indifferent_access.slice(*COLUMNS)

      return if (cols = COLUMNS - @values.keys).blank?

      raise "following attrs are not assigned: #{cols.sort.join(',')}"
    end

    def name
      return @name if defined?(@name)

      value = Array.wrap(@values.fetch(:name))

      if rubric?
        value << I18n.t('rubrics.name.rubrics_count_text', rubrics_count: rubrics_count) if rubrics_count.to_i.positive?
        value << I18n.t('rubrics.name.photos_count_text', photos_count: photos_count) if photos_count.to_i.positive?
      end

      @name = value.join(', ')
    end

    def image_size(apply_rotation: false)
      if size?
        image_props.image_size(:thumb, apply_rotation: apply_rotation)
      else
        DEFAULT_SIZE
      end
    end

    def proxy_url
      url_generator.generate(
        :thumb,
        image_size
      )
    end

    def rubric?
      model_type == 'Rubric'
    end

    delegate :css_transform, :turned?, to: :image_props

    def rotated
      props&.[]('rotated')
    end

    def effects
      props&.[]('effects')
    end

    private

    def image_props
      @image_props ||= ImageProps.new(self)
    end

    def size?
      width && height
    end

    def url_generator
      @url_generator ||= ::ProxyUrls::Photo.new(self)
    end
  end
end
