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
    # left
    if e.keyCode == 37
      $link = $('.photo-left')
      Turbolinks.visit $link.attr('href') if $link.length > 0

    # right
    if e.keyCode == 39
      $link = $('.photo-right')
      Turbolinks.visit $link.attr('href') if $link.length > 0

    # space
    if e.keyCode == 32
      $('.cart-selector').click()
      return false

    if e.keyCode == 113
      $link = $('.photo-edit-button')
      Turbolinks.visit $link.attr('href') if $link.length > 0

  .on 'change', '#preview_id', ->
    Cookies.set('preview_id', $(this).val())
    Turbolinks.visit(window.location)
