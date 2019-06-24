class PhotosController < ApplicationController
  def show
    @page = Page.new(params[:page_id])
    @photos = @page.find_photo_with_next_and_prev(params[:id])
  end
end
