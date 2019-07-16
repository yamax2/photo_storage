module Yandex
  class ReviseDirService
    include ::Interactor

    delegate :dir, :token, :errors, to: :context

    def call
      context.errors ||= {}

      revise_photos

      errors[nil] = dav_response.keys unless dav_response.empty?
    rescue YandexPhotoStorage::NotFoundError
      errors[nil] = ["dir #{dir} not found on remote storage"]
    end

    private

    def dav_response
      return @dav_response if defined?(@dav_response)

      client = YandexPhotoStorage::Dav::Client.new(access_token: token.access_token)

      @dav_response = client.
        propfind(name: "#{token.dir}/#{dir}", depth: 1).
        delete_if { |_, info| info[:resourcetype] == :folder }.
        transform_keys do |key|
          key.sub(%r{^#{token.dir}/}, '')
        end
    end

    def match_photo_info(photo, dav_info)
      errors = []

      errors << 'size mismatch' if photo.size != dav_info.fetch(:getcontentlength)
      errors << 'content type mismatch' if photo.content_type != dav_info.fetch(:getcontenttype)
      errors << 'etag mismatch' if photo.md5 != dav_info.fetch(:getetag)

      errors
    end

    def photos
      Photo.
        uploaded.
        where(yandex_token: token).
        where(Photo.arel_table[:storage_filename].matches_regexp("^#{dir}[a-z0-9]+\.[A-z]+$"))
    end

    def revise_photos
      photos.each do |photo|
        dav_info = dav_response.delete(photo.storage_filename)

        if dav_info.nil?
          errors[photo.id] = ['not found on remote storage']
          next
        end

        next unless (er = match_photo_info(photo, dav_info)).present?

        errors[photo.id] = er
      end
    end
  end
end
