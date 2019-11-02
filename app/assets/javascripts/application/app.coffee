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
    switch e.keyCode
      when 37 # left
        $link = $('.photo-left')
        Turbolinks.visit $link.attr('href') if $link.length > 0

      when 39 # right
        $link = $('.photo-right')
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
