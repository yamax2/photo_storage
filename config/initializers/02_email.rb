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
  config.action_mailer.smtp_settings = {
    address: 'smtp.yandex.ru',
    port: 465,
    domain: Rails.application.credentials.email[:domain],
    user_name: Rails.application.credentials.email[:login],
    password: Rails.application.credentials.email[:password],
    authentication: :plain,
    enable_starttls_auto: true,
    tls: true
  }
end
