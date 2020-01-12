loadPhotos = ($photos) ->
  $loader = $('#loader')
  return if $loader.length == 0 || $loader.is('.active')

  $loader.addClass('active')

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

    hideLoader = response.length < limit

    $loader.hide() if hideLoader
    $loader.removeClass('active')

    hasScroll = document.body.scrollHeight - document.body.clientHeight > 360

    loadPhotos($photos) if !hasScroll && !hideLoader

$(document)
  .on 'turbolinks:load', ->
    $photos = $('.photos[data-url]')
    return unless $photos.length > 0

    controller = new ScrollMagic.Controller()
    scene = new ScrollMagic.Scene
      triggerElement: '#loader'
      triggerHook: 'onEnter'

    scene.addTo(controller)
    scene.on 'enter', ->
      loadPhotos($photos)
