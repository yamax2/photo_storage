# frozen_string_literal: true

module Admin
  class PhotosController < AdminController
    before_action :find_photo

    def update
      if @photo.update(photo_params)
        enqueue_description if params[:get_new_description]

        redirect_to action: :edit, id: @photo.id
      else
        render 'edit'
      end
    end

    def destroy
      @photo.destroy

      redirect_to admin_root_path, notice: t('.success', name: @photo.name)
    end

    private

    def find_photo
      @photo = Photo.uploaded.find(params[:id])
    end

    def photo_params
      params.require(:photo).permit(
        :name, :rubric_id, :tz, :original_timestamp, :description, :rotated, :hide_on_map, effects: [], lat_long: []
      ).tap do |par|
        normalize_lat_long_param(par)

        unless (value = par[:rotated]).nil?
          par[:rotated] = value.to_i.nonzero?
        end

        par[:hide_on_map] = par[:hide_on_map].to_i == 1 ? true : nil

        normalize_effects_param(par)
      end
    end

    def normalize_lat_long_param(par)
      par[:lat_long] = nil if (value = par[:lat_long]).present? && value.filter_map(&:presence).empty?
    end

    def normalize_effects_param(par)
      return if (value = par[:effects]).blank?

      par[:effects] = value.map!(&:presence).compact!.presence
    end

    def enqueue_description
      ::Photos::EnqueueLoadDescriptionService.call!(photo: @photo)

      flash[:notice] = I18n.t('admin.photos.edit.get_new_description_enqueued', name: @photo.name)
    end
  end
end
