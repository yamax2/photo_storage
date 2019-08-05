module Api
  module V1
    module Admin
      module Photos
        class CartController < ::ActionController::API
          before_action :find_photo

          def create
            Cart::PhotoService.call!(photo: @photo, remove: false)
          end

          def destroy
            Cart::PhotoService.call!(photo: @photo, remove: true)
          end

          private

          def find_photo
            @photo = Photo.find(params.require(:photo_id))
          end
        end
      end
    end
  end
end
