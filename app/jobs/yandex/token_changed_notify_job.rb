# frozen_string_literal: true

require 'net/http'

module Yandex
  class TokenChangedNotifyJob
    include Sidekiq::Worker
    sidekiq_options queue: :tokens

    def perform
      request = ::Net::HTTP::Get.new(request_uri.request_uri)
      response = http.start { |req| req.request(request) }

      raise 'proxy reload error' unless response.is_a?(::Net::HTTPSuccess)
    end

    private

    def http
      ::Net::HTTP.new(request_uri.host, request_uri.port).tap do |http|
        http.use_ssl = Rails.application.routes.default_url_options[:protocol] == 'https'
      end
    end

    def request_uri
      @request_uri ||= URI.parse(Rails.application.routes.url_helpers.proxy_reload_url)
    end
  end
end
