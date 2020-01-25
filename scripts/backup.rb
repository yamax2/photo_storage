# frozen_string_literal: true

# backup script for db (script server)
# requires simple_gmail gem

require 'simple_gdrive'
require 'fileutils'

SimpleGdrive.configure do |config|
  config.client_secrets_file = '/home/photos/client_secrets.json'
  config.base_folder_id = '...'
  config.credential_file = '/home/photos/credentials.yaml'
end

# SimpleGdrive.clear_trash
# puts 'trash bin cleared'

# SimpleGdrive.clear(move_to_trash: true)
# puts 'folder cleared'

Dir['/home/photos/arc/*.7z'].each do |fn|
  SimpleGdrive.upload File.basename(fn), fn
  FileUtils.rm_rf(fn)

  puts "uploaded #{fn}"
end
