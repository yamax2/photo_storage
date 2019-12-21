# frozen_string_literal: true

namespace :deploy do
  desc 'Restart Puma'
  task restart_puma: :environment do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :systemctl, :restart, :'photos.puma'
    end
  end

  desc 'Restart Sidekiq'
  task restart_sidekiq: :environment do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :systemctl, :restart, :'photos.sidekiq'
    end
  end

  after :finishing, :restart_puma
  after :finishing, :restart_sidekiq
end
