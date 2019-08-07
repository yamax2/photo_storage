class PhotosController < ApplicationController
  helper_method :in_cart?

  def show
    @page = Page.new(params[:page_id])
    @photos = @page.find_photo_with_next_and_prev(params[:id])
  end

  private

  def in_cart?(photo)
    RedisClassy.redis.sismember("cart:photos:#{photo.rubric_id}", photo.id)
  end
end
