# frozen_string_literal: true

server '11.10.79.1', user: 'photos', roles: %w[app db web job], port: 2222
set :rails_env, :production
set :branch, :develop
