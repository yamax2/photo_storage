# frozen_string_literal: true

module Yandex
  # relation with some extended attrs
  class TokenSummaryFinder
    def call
      @table = Token.arel_table
      union_table = Arel::Table.new('u')

      fix_columns Token.select(
        @table[Arel.star],
        Token.
          select(union_table['last_upload_at'].maximum).
          from(max_date_relation).
          arel.
          as('last_upload_at')
      )
    end

    def self.call
      new.call
    end

    private

    def summary_for(model)
      model_table = model.arel_table

      model.
        uploaded.
        select(model_table[:created_at].maximum.as('last_upload_at')).
        where(model_table[:yandex_token_id].eq(@table[:id])).
        arel
    end

    def max_date_relation
      Arel::Nodes::UnionAll.new(
        summary_for(Photo),
        summary_for(Track)
      ).as('u')
    end

    def fix_columns(relation)
      relation.tap do |r|
        r.attribute_types['last_upload_at'] = r.attribute_types['created_at']
      end
    end
  end
end
