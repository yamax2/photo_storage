nextPageTimeout = null
player = null

$(document)
  .on 'click', '.cart-selector', ->
    $this = $(this)
    selected = $this.is('.selected')

    $.ajax $this.data('url'),
           type: if selected then 'DELETE' else 'POST'
           error: (jqXHR, textStatus, errorThrown) ->
             console.log "AJAX Error: #{textStatus}"
           success: ->
             $this.toggleClass('selected')

  .on 'click', '.photo-set-main-button', ->
    $this = $(this)

    $.ajax
      url: $this.data('url')
      type: 'put'
      contentType: 'application/json'
      data: JSON.stringify({rubric: {main_photo_id: $this.data('photo-id')}})
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
      success: ->
        Turbolinks.visit(window.location)

    false

  .on 'turbolinks:before-visit', ->
    if player
      player.dispose()
      player = null

  .on 'turbolinks:load', ->
    loadTimeout = setTimeout ->
      $('#throbber').show()
      $(this).addClass('loading')
    , 100

    $('#mainimg').on 'load', ->
      clearTimeout loadTimeout

      $('#throbber').hide()
      $('a.photo-arrow').addClass('loaded')
      $(this).removeClass('loading')

    if $('#main_video').length > 0
      player = videojs('main_video', {controlBar: {pictureInPictureToggle: false}})
      player.ready ->
        $('a.photo-arrow').addClass('loaded')

    clearTimeout(nextPageTimeout) if nextPageTimeout?
    $link = $('a.photo-arrow-right')

    if $link.length > 0
      url = new URL(window.location)
      waitForNext = url.searchParams.get('next')

      if waitForNext
        $content = $('.photo-content')

        nextPageTimeout = setTimeout ->
          url = $link.attr('href')
          url += "?next=#{waitForNext}" if $content.data('end') > 1

          Turbolinks.visit url

        , waitForNext * 1000

  .on 'keydown', (e) ->
    switch e.keyCode
      when 37 # left
        $link = $('a.photo-arrow-left')
        Turbolinks.visit $link.attr('href') if $link.length > 0

      when 39 # right
        $link = $('a.photo-arrow-right')
        Turbolinks.visit $link.attr('href') if $link.length > 0

      when 32 # space
        $('.cart-selector').click()
        return false

      when 113 # f2
        $link = $('.photo-edit-button')
        window.open $link.attr('href') if $link.length > 0

  .on 'change', '#preview_id', ->
    Cookies.set('preview_id', $(this).val())
    Turbolinks.visit(window.location)
