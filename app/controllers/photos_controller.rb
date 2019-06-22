class PhotosController < ApplicationController
  def show
    @rubric = RubricFinder.call(params[:page_id])
    @photo = @rubric.photos.uploaded.find(params[:id]).decorate
  end
end
