crumb :root do
  link t('admin.partials.menu.dashboard'), admin_root_path
end

crumb :yandex_tokens do
  link t('admin.partials.menu.yandex_tokens'), admin_yandex_tokens_path
end

crumb :yandex_token do |token|
  link token.login, edit_admin_yandex_token_path(token)
  parent :yandex_tokens
end

crumb :rubrics do
  link t('admin.partials.menu.rubrics'), admin_rubrics_path
end

crumb :rubric do |rubric|
  link rubric.name.presence || t('admin.rubrics.form.title'), rubric.persisted? ? admin_rubric_path(rubric) : '#'
  parent :rubrics
end
