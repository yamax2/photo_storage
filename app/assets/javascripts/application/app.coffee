$(document)
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
