$(document)
  .on 'click', '#menuToggle', ->
    $('body').toggleClass('open')
    false
