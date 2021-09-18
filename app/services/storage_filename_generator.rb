# frozen_string_literal: true

class StorageFilenameGenerator
  PARTITION_SIZE = 500

  attr_reader :model

  def initialize(model, partition: true)
    @partition = partition
    @model = model
  end

  def call
    if @partition
      [
        partition_number(model.id / (PARTITION_SIZE**2)),
        partition_number(model.id / PARTITION_SIZE),
        new_filename
      ].join('/')
    else
      new_filename
    end
  end

  def self.call(model, partition: true)
    new(model, partition: partition).call
  end

  private

  def new_filename
    [
      model.id.to_s,
      SecureRandom.hex(20),
      File.extname(model.original_filename).to_s.downcase
    ].join
  end

  def partition_number(value)
    raise "fixme: #{model.id}" if value / PARTITION_SIZE >= PARTITION_SIZE

    (value % PARTITION_SIZE).to_s.rjust(3, '0')
  end
end
