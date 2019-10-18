# frozen_string_literal: true

# FIXME: NULLS FIRST for arel
#
# how to use it:
#   Photo.order(PhotosNullsFirstAsc.new(Photo.arel_table[:id]))
PhotosNullsFirstAsc = Class.new(Arel::Nodes::Ascending)
Arel::Visitors::ToSql.define_method(:visit_PhotosNullsFirstAsc) do |o, collector|
  visit(o.expr, collector) << ' NULLS FIRST'
end
