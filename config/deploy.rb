# frozen_string_literal: true

lock '~> 3.14.0'

set :application, 'photo_storage'
set :repo_url, 'git@github.com:yamax2/photo_storage.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/photos/photos'

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

append :linked_files, 'config/database.yml', 'config/redis.yml', 'config/credentials/production.key', 'config/email.yml'
append :linked_dirs, 'log', 'tmp'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

set :keep_releases, 1
set :ssh_options, verify_host_key: :secure
set :ssh_options, forward_agent: true, user: 'photos'

set :rbenv_type, :user
set :rbenv_ruby, '2.7.2'
set :default_env, {disable_binstubs: '1'}
