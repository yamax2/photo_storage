# frozen_string_literal: true

module Admin
  class TracksController < AdminController
    before_action :find_rubric

    def create
      @track = @rubric.tracks.new(track_params)

      context = ::Tracks::EnqueueProcessService.call(
        track: @track,
        uploaded_io: params.require(:track).require(:content)
      )

      if context.success?
        redirect_to admin_rubric_tracks_path(@rubric)
      else
        render 'new'
      end
    end

    def destroy

    end

    def edit

    end

    def index

    end

    def new
      @track = @rubric.tracks.new
    end

    def update

    end

    private

    def find_rubric
      @rubric = Rubric.find(params[:rubric_id])
    end

    def track_params
      params.require(:track).permit(:name)
    end
  end
end
