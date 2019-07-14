$(document)
  .on 'submit', '#positions-form', ->
    value = ($('#positions-form ol > li').map -> $(this).data('id')).toArray()
    $('#positions_data').val(value.join(','))

  .on 'turbolinks:load', ->
     $('.rubrics-sorting').sortable()
