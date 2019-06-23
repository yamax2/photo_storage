class PhotosController < ApplicationController
  def show
    @page = Page.new(params[:page_id])
    @photo = @page.rubric.photos.uploaded.find(params[:id]).decorate
  end
end
