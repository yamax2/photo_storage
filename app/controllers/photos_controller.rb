class PhotosController < ApplicationController
  def show
    @rubric = Rubric.find(params[:page_id])
    @photo = @rubric.photos.find(params[:id]).decorate
  end
end
