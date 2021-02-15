# frozen_string_literal: true

module Photos
  class FrontCameraService
    include ::Interactor

    delegate :photo, :action, to: :context

    def call
      return if photo.exif.blank?

      find_action
      return unless action && [photo.width, photo.height].include?(action.fetch(:dimension))

      apply_action
      photo.save!
    end

    private

    def apply_action
      photo.effects = Array.wrap(action[:effects]) if action.key?(:effects)
      photo.rotated = action[:rotated] if action.key?(:rotated)
    end

    def find_action
      camera = photo.exif.values_at(*%w[make model])

      context.action = Rails.application.config.front_cameras&.find { |item| item.values_at(:make, :model) == camera }
    end
  end
end
