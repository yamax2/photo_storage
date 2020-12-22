# frozen_string_literal: true

module Admin
  class PhotosController < AdminController
    before_action :find_photo

    def update
      if @photo.update(photo_params)
        redirect_to action: :edit, id: @photo.id
      else
        render 'edit'
      end
    end

    private

    def find_photo
      @photo = Photo.uploaded.find(params[:id])
    end

    def photo_params
      params.require(:photo).permit(
        :name, :rubric_id, :tz, :original_timestamp, :description, :rotated, effects: [], lat_long: []
      ).tap do |par|
        normalize_lat_long_param(par)

        unless (value = par[:rotated]).nil?
          par[:rotated] = value.to_i.nonzero?
        end

        normalize_effects_param(par)
      end
    end

    def normalize_lat_long_param(par)
      par[:lat_long] = nil if (value = par[:lat_long]).present? && value.map(&:presence).compact.empty?
    end

    def normalize_effects_param(par)
      return if (value = par[:effects]).blank?

      par[:effects] = value.map!(&:presence).compact!.presence
    end
  end
end
