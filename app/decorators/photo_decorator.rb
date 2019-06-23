class PhotoDecorator < Draper::Decorator
  delegate_all

  def thumb_size
    return @thumb_size if defined?(@thumb_size)

    thumb_width = thumb_width(:thumb)
    @thumb_size = [thumb_width, height * thumb_width / width]
  end

  def url(size = :original)
    return unless storage_filename.present?

    url = [proxy_url, storage_filename].join('/')
    url << "?preview&size=#{thumb_width(size)}" unless size == :original

    url
  end

  private

  def proxy_url(other: false)
    actual_dir = other ? yandex_token.other_dir : yandex_token.dir

    "#{Rails.application.routes.default_url_options[:protocol]}://#{Rails.application.config.proxy_domain}." \
        "#{Rails.application.routes.default_url_options[:host]}#{actual_dir}"
  end

  def thumb_width(size)
    width = Rails.application.config.photo_sizes.fetch(size)

    if width.respond_to?(:call)
      width.call(self)
    else
      width
    end
  end
end
