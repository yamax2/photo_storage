# frozen_string_literal: true

module Yandex
  # finds resources for backup
  class ResourceFinder
    def call # rubocop:disable Metrics/MethodLength
      table = Arel::Table.new('resources')

      Token.
        joins(info_query(table)).
        group(:id, table[:id], table[:folder_index]).
        order(:id, folder_index: :desc).
        select(
          Token.arel_table[Arel.star],
          table[:folder_index],
          group_case(table, 'other', :size),
          group_case(table, 'other', :count),
          group_case(table, 'photo', :size),
          group_case(table, 'photo', :count)
        )
    end

    def self.call
      new.call
    end

    private

    def group_case(table, resource, attr)
      Arel::Nodes::Case.
        new(table[:resource]).
        when(resource).
        then(table[attr]).
        sum.
        as("#{resource}_#{attr}")
    end

    def info_query(table)
      Arel::Nodes::InnerJoin.new(
        resources_query.as('resources'),
        Arel::Nodes::On.new(table[:id].eq(Token.arel_table[:id]))
      )
    end

    def resources_query
      union_all \
        resource_query(Photo.images, 'photo', Photo.arel_table[:size]),
        resource_query(Photo.videos, 'other', Photo.arel_table[:size]),
        resource_query(Photo.videos, 'other', "(photos.props->>'preview_size')::int"),
        resource_query(Photo.videos, 'other', "(photos.props->>'video_preview_size')::int"),
        resource_query(Track.all, 'other', Track.arel_table[:size])
    end

    def resource_query(scope, resource_name, size_attr) # rubocop:disable Metrics/AbcSize
      attr = size_attr
      attr = Arel.sql(attr) if attr.is_a?(String)

      scope.uploaded.select(
        scope.arel_table[:yandex_token_id].as('id'),
        scope.arel_table[:folder_index].as('folder_index'),
        attr.sum.as('size'),
        Arel.star.count.as('count'),
        Arel::Nodes::Quoted.new(resource_name).as('resource')
      ).group(:yandex_token_id, :folder_index).arel
    end

    def union_all(*queries)
      if queries.size < 2
        queries.first
      else
        Arel::Nodes::UnionAll.new(
          queries.shift,
          union_all(*queries)
        )
      end
    end
  end
end
