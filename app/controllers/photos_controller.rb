# frozen_string_literal: true

class PhotosController < ApplicationController
  helper_method :in_cart?, :preview_id

  rescue_from ActiveRecord::RecordNotFound, with: :try_to_find_rubric

  def show
    @rubric = RubricFinder.call(params[:page_id])
    @photos = Rubrics::CurrentPhotoFinder.call(@rubric.id, params[:id])
  end

  private

  def in_cart?(photo)
    Rails.application.redis.call('SISMEMBER', "cart:photos:#{photo.rubric_id}", photo.id)
  end

  def preview_id
    @preview_id ||=
      if (value = cookies[:preview_id]).present?
        value.to_sym
      else
        :preview
      end
  end

  def try_to_find_rubric
    photo = Photo.find(params[:id])

    redirect_to page_photo_path(photo.rubric_id, photo.id)
  end
end
