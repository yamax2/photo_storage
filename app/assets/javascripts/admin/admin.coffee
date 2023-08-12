$(window)
  .on 'beforeunload', ->
    $('body').data('process')

$(document)
  .on 'click', '#menuToggle', ->
    $('body').toggleClass('open')
    false

  .on 'click', '#stop-button', ->
    text = $(this).data('cofirm')
    $('#drag-and-drop-zone').dmUploader('cancel') if confirm(text)

  .on 'submit', '#positions-form', ->
    value = ($('#positions-form ol > li').map -> $(this).data('id')).toArray()
    $('#data').val(value.join(','))

  .on 'click', '.btn-clear', ->
    $('input', $(this).closest('.form-group')).val('')

  .on 'turbolinks:load', ->
    $('.rubrics-sorting').sortable()

    $tz = $('#tz')
    $tz.val Intl.DateTimeFormat().resolvedOptions().timeZone
    $('option:first-child', $tz).attr('selected', 'selected') unless $tz.val()

    $('#rubrics')
      .on 'select_node.jstree', (e, node) ->
        $('#drag-and-drop-zone').data('rubric_id', node.node.id)
        $('#rubric-name-text').text(node.node.text)

      .on 'ready.jstree', ->
        id = $('ul > li:first-child', this).attr('id')

        $(this).jstree('select_node', id) if id
        $('#drag-and-drop-zone').toggle(id?)

    $('#drag-and-drop-zone').dmUploader
      url: '/api/v1/admin/uploads'
      extraData: ->
        {rubric_id: $(this).data('rubric_id'), tz: $('#tz').val()}
      headers:
        'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
      fieldName: 'content'
      extFilter: ['jpg', 'jpeg', 'png', 'gpx']
      onDragEnter: ->
        this.addClass('active')
      onDragLeave: ->
        this.removeClass('active')
      onNewFile: (id, file) ->
        $('body').data('process', true)
        $('.rubric-container .blocker').show()
        $('#tz').prop('disabled', true)
        $('#stop-button').show()
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
        $(this).data('errors', true)
        ui_multi_update_file_status(id, 'danger', message)
        ui_multi_update_file_progress(id, 0, 'danger', false)
      onComplete: ->
        $this = $(this)

        alert $this.data('with_errors') if $this.data('errors')
        $this.removeData('errors')

        $('.rubric-container .blocker').hide()
        $('body').removeData('process')
        $('#tz').prop('disabled', false)
        $('#stop-button').hide()
