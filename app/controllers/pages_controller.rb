# frozen_string_literal: true

class PagesController < ApplicationController
  helper_method :with_photos?, :with_rubrics?

  def show
    if (rubric_id = params[:id]).present?
      @rubric = RubricFinder.call(rubric_id).decorate
    end

    @rubrics = rubrics.
      with_photos.
      preload(main_photo: :yandex_token).
      default_order.
      decorate

    redirect_to root_path unless with_rubrics? || with_photos?
  end

  private

  def rubrics
    @rubric&.rubrics || Rubric.where(rubric_id: nil)
  end

  def with_photos?
    @rubric.photos_count.positive? && Rubrics::PhotosFinder.call(@rubric.id).exists?
  end

  def with_rubrics?
    @rubric.nil? || @rubric.rubrics_count.positive? && @rubrics.any?
  end
end
