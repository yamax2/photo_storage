$(document)
  .on 'click', '.rubric-select', ->
    $('#rubric-modal').modal('show')

  .on 'click', '.rubric-clear', ->
    $this = $(this)

    $this.closest('.input-group').find('input').val $this.data('text')
    $($this.data('id')).val('')


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

  .on 'submit', '.photo-edit-form', ->
    $checkbox = $('#get_new_description', this)

    if $checkbox.is(':checked') && $('#photo_description', this).val().length > 0
      alert $checkbox.data('error')
      false
