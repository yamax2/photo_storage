# frozen_string_literal: true

Rails.application.configure do
  config.front_cameras = config_for(:front_cameras).fetch(:detects)
end
