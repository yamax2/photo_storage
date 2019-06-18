$(document)
  .on 'click', '#menuToggle', ->
    $('body').toggleClass('open')
    false

  .on 'turbolinks:load', ->
    $("#drag-and-drop-zone").dmUploader
      url: '/admin/photos'
      extraData: ->
        {rubric_id: 3}
      headers:
        'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
      fieldName: 'image'
      extFilter: ['jpg', 'jpeg', 'png']
      onDragEnter: ->
        this.addClass('active')
      onDragLeave: ->
        this.removeClass('active')
