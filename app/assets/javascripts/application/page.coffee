renders = []
controller = null

loadPhotos = ($photos) ->
  $loader = $('#loader')
  return unless $loader.length > 0

  offset = parseInt($loader.attr('data-offset') || 0)
  limit = $loader.attr('data-limit') || 10

  url = "#{$photos.attr('data-url')}?limit=#{limit}&offset=#{offset}"

  $.get url, (response) ->
    if response.length > 0
      html = ''

      for photo in response
        actual_size = photo.properties.actual_image_size

        style = "width: #{actual_size[0]}px; height: #{actual_size[1]}px; min-height: #{actual_size[1]}px"

        img_style = "width: #{photo.image_size[0]}px; height: #{photo.image_size[1]}px; " +
                    "min-height: #{photo.image_size[1]}px"

        if photo.properties.css_transform
          img_style += "; transform: #{photo.properties.css_transform}"

        if photo.properties.turned
          value = 100 * actual_size[1] / actual_size[0]

          html += "<style>@media (max-width: 992px) { #lphoto_#{photo.id} { min-width: #{value}vw !important; }" +
                  " #llink_#{photo.id} { height: #{value}vw !important; } }</style>"

        html += "<a title=\"#{photo.name}\" class=\"photo\" style=\"#{style}\" href=\"#{photo.url}\" " +
                "id=\"llink_#{photo.id}\">" +
                "<img id=\"lphoto_#{photo.id}\" src=\"#{photo.preview}\" style=\"#{img_style}\"" +
                " onload=\"$(this).parent().addClass('loaded')\">" +
                "<div class=\"photo-name\"><span>#{photo.name}</span></div></a>"

      $(html).insertBefore($loader)
      $loader.attr('data-offset', offset + response.length)

    if response.length < limit
      $loader.hide()
      renders.length = 0
    else if renders.shift()
      loadPhotos($photos)

$(document)
  .on 'turbolinks:before-visit', ->
    return unless controller?

    controller.destroy(true)
    controller = null

  .on 'turbolinks:load', ->
    renders.length = 0

    $photos = $('.photos[data-url]')
    return unless $photos.length > 0

    controller = new ScrollMagic.Controller()
    scene = new ScrollMagic.Scene
      triggerElement: '#loader'
      triggerHook: 'onEnter'

    scene.addTo(controller)
    scene.on 'enter', ->
      renders.push(true)
      loadPhotos($photos) if renders.length == 1
