# frozen_string_literal: true

module Logging
  class Subscriber < RailsSemanticLogger::ActionController::LogSubscriber
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
    def process_action(event)
      controller_logger(event).info do
        payload = event.payload.dup

        payload[:params] = payload[:params].to_unsafe_h unless payload[:params].is_a?(Hash)
        payload[:params].delete(payload[:params][:controller].split('/').last) if payload[:params][:controller]
        payload[:params] = payload[:params].except(*INTERNAL_PARAMS)
        payload.delete(:params) if payload[:params].empty?

        payload[:path] = extract_path(payload[:path]) if payload.key?(:path)

        exception = payload.delete(:exception)
        if payload[:status].nil? && exception.present?
          exception_class_name = exception.first
          payload[:status]     = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)
        end

        # Rounds off the runtimes. For example, :view_runtime, :mongo_runtime, etc.
        payload.each_key do |key|
          payload[key] = payload[key].to_f.round(2) if key.to_s.match?(/(.*)_runtime/)
        end

        payload[:allocations] = event.allocations if event.respond_to?(:allocations)
        payload.except!(:headers, :response)

        req = payload.delete(:request)

        {
          duration: event.duration,
          payload:,
          client_ip: req.remote_ip,
          request_id: req.request_id
        }
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
  end
end
