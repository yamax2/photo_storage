# frozen_string_literal: true

# moves uploaded_io to tmp and returns filename
class UploadFileService
  include Singleton

  def call(uploaded_io)
    dir = Rails.root.join('tmp/files')
    local_filename = SecureRandom.hex(26)

    FileUtils.mkdir_p(dir)
    FileUtils.mv(uploaded_io.tempfile, dir.join(local_filename))

    local_filename
  end

  def self.move(uploaded_io)
    instance.call(uploaded_io)
  end
end
