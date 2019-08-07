$(document)
  .on 'click', '.cart-selector', ->
    $this = $(this)
    selected = $this.is('.selected')

    $.ajax $this.data('url'),
           type: if selected then 'DELETE' else 'POST'
           error: (jqXHR, textStatus, errorThrown) ->
             console.log "AJAX Error: #{textStatus}"
           success:
             $this.toggleClass('selected')

  .on 'turbolinks:load', ->
    $('#mainimg').on 'load', ->
      $('.photo-right, .photo-left').show()

    $('.photos .photo > img, .rubrics .rubric > img').lazy()

  .on 'keydown', (e) ->
    if e.keyCode == 37
      $link = $('.photo-left')
      Turbolinks.visit $('.photo-left').attr('href') if $link.length > 0

    if e.keyCode == 39
      $link = $('.photo-right')
      Turbolinks.visit $('.photo-right').attr('href') if $link.length > 0

    if e.keyCode == 32
      $('.cart-selector').click()
      return false
