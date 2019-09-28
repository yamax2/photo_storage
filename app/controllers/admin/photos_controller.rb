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
        :name,
        :rubric_id,
        :tz,
        :original_timestamp,
        :description,
        lat_long: []
      )
    end
  end
end
