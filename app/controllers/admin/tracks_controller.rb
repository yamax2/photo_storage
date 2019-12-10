# frozen_string_literal: true

module Admin
  class TracksController < AdminController
    before_action :find_rubric
    before_action :find_track, only: %i[edit update destroy]

    def destroy
      @track.destroy

      redirect_to admin_rubric_tracks_path(@rubric), notice: t('.success', name: @track.name)
    end

    def index
      @search = Track.where(rubric: @rubric).ransack(params[:q])
      @tracks = @search.result.page(params[:page]).decorate
    end

    def update
      if @track.update(track_params)
        redirect_to admin_rubric_tracks_path(@rubric)
      else
        render 'edit'
      end
    end

    private

    def find_rubric
      @rubric = Rubric.find(params[:rubric_id])
    end

    def find_track
      @track = @rubric.tracks.find(params[:id])
    end

    def track_params
      params.require(:track).permit(:name)
    end
  end
end
