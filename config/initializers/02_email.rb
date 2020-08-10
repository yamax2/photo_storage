# frozen_string_literal: true

Rails.application.configure do
  # google smtp
  # config.action_mailer.smtp_settings = {
  #  address: 'smtp.gmail.com',
  #  port: 587,
  #  domain: Rails.application.secrets.email_domain,
  #  user_name: Rails.application.secrets.email_login,
  #  password: Rails.application.secrets.email_pass,
  #  authentication: :plain,
  #  openssl_verify_mode: 'none',
  #  enable_starttls_auto: true
  # }

  # yandex smtp
  # config.action_mailer.smtp_settings = {
  #   address: 'smtp.yandex.ru',
  #   port: 465,
  #   domain: ENV.fetch('PHOTOSTORAGE_SMTP_DOMAIN', Rails.application.credentials.email.try(:[], :domain)),
  #   user_name: ENV.fetch('PHOTOSTORAGE_SMTP_USER', Rails.application.credentials.email.try(:[], :login)),
  #   password: ENV.fetch('PHOTOSTORAGE_SMTP_USER', Rails.application.credentials.email.try(:[], :password)),
  #   authentication: :plain,
  #   enable_starttls_auto: true,
  #   tls: true
  # }

  info = YAML.load(
    ERB.new(File.read(Rails.root.join('config/email.yml'))).result
  ).fetch(Rails.env).deep_symbolize_keys!

  config.action_mailer.smtp_settings = info.fetch(:smtp)
  config.mail_default_from = info.fetch(:default_from)
end
