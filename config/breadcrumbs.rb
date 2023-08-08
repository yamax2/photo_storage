# frozen_string_literal: true

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

crumb :rubric_positions do
  link t('admin.partials.menu.rubric_positions'), admin_rubrics_positions_path
  parent :rubrics
end

crumb :rubric do |rubric|
  link rubric.name.presence || t('admin.rubrics.form.title'), rubric.persisted? ? edit_admin_rubric_path(rubric) : '#'
  parent :rubrics
end

crumb :tracks do |rubric|
  link t('admin.partials.menu.tracks'), admin_rubric_tracks_path(rubric)
  parent :rubric, rubric
end

crumb :track do |track|
  link track.name, '#'
  parent :tracks, track.rubric
end

crumb :cameras do
  link t('admin.reports.cameras.index.title'), '#'
end

crumb :activities do
  link t('admin.reports.activities.index.title'), '#'
end
