$(document)
  .on 'blur', '.datetimepicker', ->
    $(this).datetimepicker('hide')

  .on 'turbolinks:load', ->
    $('.datetimepicker')
      .datetimepicker
        locale: 'ru'
        ignoreReadonly: true
        format: 'DD.MM.YYYY HH:mm:ss'
        buttons:
          showClose: true
        icons:
          clear: 'fa fa-trash'
