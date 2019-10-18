# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.email[:login]

  layout 'mailer'

  delegate :admin_emails, to: 'Rails.application.config'
end
