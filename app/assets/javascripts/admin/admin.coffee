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

  .on 'turbolinks:load', ->
    $('#rubrics')
      .jstree
        core:
          data:
            url: '/api/v1/admin/rubrics'
            data: (node) ->
              id: node.id unless node.id == '#'
        plugins: ['wholerow']

      .on 'ready.jstree', ->
        id = $('ul > li:first-child', this).attr('id')

        $(this).jstree('select_node', id) if id
        $('#drag-and-drop-zone').toggle(id?)

      .on 'select_node.jstree', (e, node) ->
        $('#drag-and-drop-zone').data('rubric_id', node.node.id)
        $('#rubric-name-text').text(node.node.text)

    $('#drag-and-drop-zone').dmUploader
      url: '/admin/photos'
      extraData: ->
        {rubric_id: $(this).data('rubric_id')}
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
        $('.rubric-container .blocker').show()
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
        ui_multi_update_file_status(id, 'danger', message)
        ui_multi_update_file_progress(id, 0, 'danger', false)
      onComplete: ->
        $('.rubric-container .blocker').hide()
        $('body').removeData('process')
        $('#stop-button').hide()
