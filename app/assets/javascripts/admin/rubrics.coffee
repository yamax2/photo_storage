rubric_timeout = null

$(document)
  .on 'input', '.rubric_name_search', ->
    $tree = $($(this).data('tree'))

    clearTimeout(rubric_timeout) if rubric_timeout
    rubric_timeout = setTimeout( ( ->
      $tree.jstree(true).settings.core.data.url = "/api/v1/admin/rubrics?str=#{$(this).val()}"
      $tree.jstree(true).refresh()).bind(this)
    , 500)

  .on 'turbolinks:load', ->
    $('.rubrics-tree')
      .jstree
        core:
          data:
            url: '/api/v1/admin/rubrics'
            data: (node) ->
              id: node.id unless node.id == '#'
        plugins: ['wholerow']
