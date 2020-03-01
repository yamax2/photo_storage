# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.action_mailer.smtp_settings[:user_name]

  layout 'mailer'

  delegate :admin_emails, to: 'Rails.application.config'
end
