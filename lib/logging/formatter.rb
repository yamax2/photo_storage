# frozen_string_literal: true

module Logging
  class Formatter < SemanticLogger::Formatters::Raw
    KEYS_TO_SKIP = %i[pid name thread application environment format tags].freeze

    # rubocop:disable Naming/VariableNumber
    def initialize(time_format: :iso_8601, time_key: :timestamp, **args)
      super(time_format:, time_key:, **args)
    end
    # rubocop:enable Naming/VariableNumber

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def call(log, logger)
      record = super(log, logger).except(*KEYS_TO_SKIP).tap do |event|
        if (duration = event.delete(:duration_ms)).present?
          event[:duration] = duration
        end

        event[:payload]&.except!(:action, :controller, :format)
        event[:exception]&.delete(:stack_trace)

        event.except!(:file, :line)

        if (req = event[:payload]&.[](:request)).present?
          event[:client_ip] = req.ip
        end

        if event[:payload]&.key?(:exception_object)
          exception_obj = event[:payload].delete(:exception_object)

          event[:exception] = exception_obj
          event[:backtrace] = exception_obj.backtrace&.first(5)
        end

        if (req = event[:payload]&.delete(:request)).present?
          event[:client_ip] = req.ip
          event[:request_id] = req.request_id
        end

        if event[:payload]&.[](:status).to_i >= 500
          event[:level] = :error
          event[:level_index] = 4
        end

        if (tags = event.delete(:named_tags)).present?
          event.merge!(tags)
        end
      end

      if (payload = record.delete(:payload)).present?
        record.merge!(payload)
      end

      record.to_json
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  end
end
