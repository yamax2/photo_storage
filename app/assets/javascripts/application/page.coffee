renders = []

loadPhotos = ($photos) ->
  $loader = $('#loader')
  return unless $loader.length > 0

  offset = parseInt($loader.attr('data-offset') || 0)
  limit = $loader.data('limit') || 10

  url = "#{$photos.data('url')}?limit=#{limit}&offset=#{offset}"

  $.get url, (response) ->
    if response.length > 0
      html = ''

      for photo in response
        style = "width: #{photo.image_size[0]}px; height: #{photo.image_size[1]}px"
        html += "<a class=\"photo\" style=\"#{style}\" href=\"#{photo.url}\">" +
                "<img src=\"#{photo.preview}\" style=\"#{style}\">" +
                "<div class=\"photo-name\"><span>#{photo.name}</span></div></a>"

      $(html).insertBefore($loader)
      $loader.attr('data-offset', offset + response.length)

    if response.length < limit
      $loader.hide()
      renders.length = 0
    else if renders.shift()
      loadPhotos($photos)

$(document)
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
