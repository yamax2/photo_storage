$(document)
  .on 'click', '.rubric-select', ->
    $('#rubric-modal').modal('show')

  .on 'shown.bs.modal', '#rubric-modal', ->
    $('.rubric_name_search').focus()

    selected = $('#photo_rubric_id').val()
    $('.rubrics-tree')
      .jstree('deselect_all')
      .jstree('select_node', selected)

  .on 'click', '.btn-photo-rubric-apply', ->
    selected = $('.rubrics-tree').jstree('get_selected', true)
    return unless selected.length > 0

    $($(this).data('id')).val(selected[0].id)
    $($(this).data('name')).val(selected[0].text)

    $('#rubric-modal').modal('hide')
