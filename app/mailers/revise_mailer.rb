# frozen_string_literal: true

class ReviseMailer < ApplicationMailer
  def failed(dir, token_id, folder_index, info)
    return unless info.present? && admin_emails.present?

    @info = info

    mail subject: t('views.revise_mailer.failed.subject', token_id:, dir:, folder_index:),
         to: admin_emails
  end
end
