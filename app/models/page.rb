class Page
  attr_reader :rubric

  def initialize(rubric_id = nil)
    @rubric = Rubric.find(rubric_id) if rubric_id.present?
  end

  def photos
    return @photos if defined?(@photos)
    return @photos = Photo.none unless @rubric

    @photos = @rubric.
      photos.
      uploaded.
      preload(:yandex_token).
      order(:original_timestamp).
      decorate
  end

  def rubrics
    return @rubrics if defined?(@rubrics)

    rubrics = @rubric&.rubrics || Rubric.where(rubric_id: nil)
    @rubrics = rubrics.with_photos.order(:id)
  end
end
