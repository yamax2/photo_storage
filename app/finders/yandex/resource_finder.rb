# frozen_string_literal: true

module Yandex
  # finds resources for backup
  class ResourceFinder
    def call
      table = Arel::Table.new('resources')

      Token.joins(info_query(table)).
        group(:id, table[:id]).order(:id).
        select(
          Token.arel_table[Arel.star],
          group_case(table, 'track', :size),
          group_case(table, 'track', :count),
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
      union = Arel::Nodes::UnionAll.new(
        resource_query(Photo).arel,
        resource_query(Track).arel
      )

      Arel::Nodes::InnerJoin.new(
        union.as('resources'),
        Arel::Nodes::On.new(table[:id].eq(Token.arel_table[:id]))
      )
    end

    def resource_query(resource_klass)
      table = resource_klass.arel_table

      resource_klass.uploaded.select(
        table[:yandex_token_id].as('id'),
        table[:size].sum.as('size'),
        Arel.star.count.as('count'),
        Arel::Nodes::Quoted.new(resource_klass.name.underscore).as('resource')
      ).group(:yandex_token_id)
    end
  end
end
