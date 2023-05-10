# frozen_string_literal: true

class MailerJob
  include Sidekiq::Worker

  sidekiq_options queue: :mailers

  def perform(mailer_klass, method_name, params)
    mailer_klass.
      constantize.
      public_send(method_name, *params).
      deliver_now
  end
end
