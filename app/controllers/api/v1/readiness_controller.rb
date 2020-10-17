# frozen_string_literal: true

module Api
  module V1
    class ReadinessController < BaseController
      def index
        RedisClassy.redis.ping
        ActiveRecord::Base.connection.execute('select 1')

        render plain: 'OK'
      end
    end
  end
end
