class StorageFilenameGenerator
  PARTITION_SIZE = 500

  attr_reader :photo

  def initialize(photo)
    @photo = photo
  end

  def call
    [
      partition_number(photo.id / PARTITION_SIZE**2),
      partition_number(photo.id / PARTITION_SIZE),
      new_filename
    ].join('/')
  end

  private

  def new_filename
    [
      photo.id.to_s,
      SecureRandom.hex(20),
      File.extname(photo.original_filename).to_s.downcase
    ].join
  end

  def partition_number(value)
    raise "fixme: #{photo.id}" if value / PARTITION_SIZE >= PARTITION_SIZE

    (value % PARTITION_SIZE).to_s.rjust(3, '0')
  end
end
