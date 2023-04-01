# frozen_string_literal: true

class ReportQuery
  include Enumerable

  Error = Class.new(StandardError)

  @report_sql = {}

  class << self
    attr_reader :report_sql

    def allowed_reports
      @allowed_reports ||= Dir[
        Rails.root.join('config/reports/*.sql')
      ].map { |name| File.basename(name, '.*').to_sym }.sort
    end
  end

  def initialize(report_type)
    if self.class.allowed_reports.exclude?(report_type)
      raise Error, "Unknown report type #{report_type}, allowed are: #{self.class.allowed_reports.inspect}"
    end

    @report_type = report_type
  end

  def each(&)
    return to_enum unless block_given?

    rows.each(&)
  end

  private

  def rows
    @rows ||= ActiveRecord::Base.connection.execute(report_sql).to_a
  end

  def report_sql
    self.class.report_sql[@report_type.to_sym] ||= Rails.root.join(
      "config/reports/#{@report_type}.sql"
    ).read
  end
end
