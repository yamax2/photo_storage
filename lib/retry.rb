# frozen_string_literal: true

class Retry
  @retry_types = {}

  Error = Class.new(StandardError)

  class << self
    def register(name, exceptions)
      raise "#{name} already registered" if @retry_types.key?(name)
      raise "#{name} no exception class provided" if (exceptions_to_register = Array.wrap(exceptions)).blank?

      if (wrong = exceptions_to_register.find { |e| e.ancestors.exclude?(Exception) }).present?
        raise "#{wrong} is not an Exception class"
      end

      @retry_types[name] = exceptions_to_register
    end

    def unregister(name)
      @retry_types.delete(name).present?
    end

    def for(name, intervals: [0, 0, 1, 2, 5, 10], &block)
      raise Error, "#{name} is not registered retry type" if (exceptions = @retry_types[name]).blank?

      new(exceptions, intervals).call(&block)
    end
  end

  def initialize(exceptions, intervals)
    @exceptions = exceptions
    @intervals = intervals
  end

  def call
    attempt = 0
    begin
      yield
    rescue *@exceptions
      raise if attempt >= @intervals.size

      sleep @intervals.fetch(attempt)
      attempt += 1

      retry
    end
  end
end

require_relative 'retry/yandex'
