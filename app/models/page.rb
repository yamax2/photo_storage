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
      joins(:yandex_token).
      includes(:yandex_token).
      decorate
  end

  def rubrics
    return @rubrics if defined?(@rubrics)

    rubrics = @rubric&.rubrics || Rubric.where(rubric_id: nil)
    @rubrics = rubrics.with_photos
  end
end
