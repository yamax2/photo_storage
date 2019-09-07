module PhotosHelper
  def photo_size_selector_opts(selected = nil)
    keys = Rails.application.config.photo_sizes.keys - [:thumb]
    options_for_select(keys.map { |size| [I18n.t(size, scope: 'photos.show.sizes'), size] }, selected)
  end
end
