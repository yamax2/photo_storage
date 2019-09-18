$(document)
  .on 'submit', '#positions-form', ->
    value = ($('#positions-form ol > li').map -> $(this).data('id')).toArray()
    $('#data').val(value.join(','))

  .on 'turbolinks:load', ->
     $('.rubrics-sorting').sortable()
