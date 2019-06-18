$(window).on 'beforeunload', ->
  $('body').data('process')

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
      onNewFile: (id, file) ->
        $('body').data('process', true)
        ui_multi_add_file(id, file)
      onBeforeUpload: (id) ->
        ui_multi_update_file_status(id, 'uploading', $(this).data('statuses-uploading'))
        ui_multi_update_file_progress(id, 0, '', true)
      onUploadCanceled: (id) ->
        ui_multi_update_file_status(id, 'warning', $(this).data('statuses-warning'))
        ui_multi_update_file_progress(id, 0, 'warning', false)
      onUploadProgress: (id, percent) ->
        ui_multi_update_file_progress(id, percent)
      onUploadSuccess: (id, data) ->
        ui_multi_update_file_status(id, 'success', $(this).data('statuses-success'))
        ui_multi_update_file_progress(id, 100, 'success', false)
      onUploadError: (id, xhr, status, message) ->
        ui_multi_update_file_status(id, 'danger', message)
        ui_multi_update_file_progress(id, 0, 'danger', false)
      onComplete: ->
        $('body').removeData('process')
