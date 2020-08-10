# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.mail_default_from

  layout 'mailer'

  delegate :admin_emails, to: 'Rails.application.config'
end
