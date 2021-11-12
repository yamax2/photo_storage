# frozen_string_literal: true

class PagesController < ApplicationController
  helper_method :with_photos?

  def show
    if (rubric_id = params[:id]).present?
      @rubric = RubricFinder.call(rubric_id)
      @summary = Rubrics::TracksSummaryService.new(@rubric.id).call if @rubric.tracks_count.positive?
    end

    redirect_to root_path unless with_rubrics? || with_photos?
  end

  private

  def with_photos?
    @rubric.photos_count.positive? && Rubrics::PhotosFinder.call(@rubric.id).exists?
  end

  def with_rubrics?
    @rubric.nil? || (@rubric.rubrics_count.positive? && @rubric.rubrics.with_objects.exists?)
  end
end
