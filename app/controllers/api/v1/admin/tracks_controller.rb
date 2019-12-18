# frozen_string_literal: true

module Api
  module V1
    module Admin
      class TracksController < BaseController
        def create
          uploaded_io = params.require(:content)

          @track = Track.new(
            name: File.basename(uploaded_io.original_filename, '.*'),
            rubric: Rubric.find(params.require(:rubric_id))
          )

          context = ::Tracks::EnqueueProcessService.call(
            track: @track,
            uploaded_io: uploaded_io
          )

          @success = context.success?

          render status: :unprocessable_entity unless @success
        end
      end
    end
  end
end
