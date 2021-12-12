#!/usr/bin/env ruby
# frozen_string_literal: true

# Warning! Still not for a production!
#
# Arguments:
#   * original video, required
#   * rubric_id, required)
#   * temporary uploaded, optional

require 'json'
require 'tempfile'
require 'date'
require 'open3'
require 'digest'
require 'openssl'
require 'base64'

BACKEND_ROOT = '11.0.2.5'

# rubocop:disable Metrics/MethodLength,Style/FormatStringToken
class VideoUploadInfo
  CONTENT_TYPES_BY_EXT = {
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime'
  }.freeze

  attr_reader :filename

  def initialize(filename, timezone: File.read('/etc/timezone').strip)
    @timezone = timezone
    @filename = filename
  end

  def preview_file
    @preview_file ||= Tempfile.new(%w[preview .jpg]).tap do |file|
      make_preview(file.path)
    end
  end

  def request_body
    return @request_body if defined?(@request_body)

    general, video = parse_media_info

    @request_body = upload_request_body(general, video)
  end

  private

  def upload_request_body(general, video) # rubocop:disable Metrics/AbcSize
    name = File.basename(filename)
    lat_long = general.dig(:extra, :xyz)

    {
      name: name,
      original_filename: name,
      original_timestamp: parse_timestamp(general[:Tagged_Date]),
      size: general[:FileSize].to_i,
      width: video.fetch(:Width).to_i,
      height: video.fetch(:Height).to_i,
      content_type: CONTENT_TYPES_BY_EXT.fetch(general.fetch(:FileExtension)),
      lat_long: lat_long ? lat_long.gsub(/[^0-9.]/, ' ').to_s.strip.split.map(&:to_f) : nil,
      md5: md5(filename),
      sha256: sha256(filename),
      preview_md5: md5(preview_file.path),
      preview_sha256: sha256(preview_file.path),
      preview_size: preview_file.size,
      tz: @timezone
    }
  end

  def parse_media_info
    json = JSON.parse(
      `mediainfo --Output=JSON #{filename}`,
      symbolize_names: true
    ).fetch(:media).fetch(:track).group_by { |item| item.fetch(:@type) }

    [
      json.fetch('General').first,
      json.fetch('Video').first
    ]
  end

  def make_preview(path)
    `ffmpeg -y -hide_banner -loglevel error -ss 00:00:01.000 -i #{filename} -vframes 1 #{path}`
  end

  def md5(filepath)
    `md5sum -b #{filepath} | awk '{print $1}'`.strip
  end

  def sha256(filepath)
    `sha256sum -b #{filepath} | awk '{print $1}'`.strip
  end

  def parse_timestamp(value)
    return if value.nil?

    DateTime.strptime(value, '%z %Y-%m-%d %H:%M:%S').iso8601
  end
end

class NewVideo
  attr_reader :rubric_id, :uploaded_original

  NotCreatedError = Class.new(StandardError)

  def initialize(rubric_id:, uploaded_original: nil)
    @rubric_id = rubric_id
    @uploaded_original = uploaded_original
  end

  def create(body)
    request_body = body.merge(rubric_id: rubric_id)
    response, err, status = Open3.capture3(generate_curl(request_body))

    raise NotCreatedError, err unless status.success?

    info = response.split('|')
    json = JSON.parse(info.first, symbolize_names: true)
    code = info.last.to_i

    return json.fetch(:id) if (200..204).cover?(code)

    raise NotCreatedError, "#{json}, code #{code}"
  end

  private

  def generate_curl(request_body)
    "curl -sL -w '|%{http_code}' '#{BACKEND_ROOT}/api/v1/admin/videos' -H 'Content-Type: application/json'" \
      " -d '{\"temporary_uploaded_filename\": \"#{uploaded_original}\", \"video\": #{request_body.to_json}'}"
  end
end

class UploadInfo
  NotFetchedError = Class.new(StandardError)

  attr_reader :id

  def initialize(id, attempts: 10)
    @id = id
    @attempts = attempts
  end

  def fetch
    response = nil

    @attempts.times do
      response, _, status = Open3.capture3("curl -sfL #{BACKEND_ROOT}/api/v1/admin/videos/#{id}")

      break if status.success?

      sleep 1
    end

    raise NotFetchedError, "info fetch failed for video #{id}" if response&.empty?

    response
  end
end

class VideoUploader
  NotUploadedError = Class.new(StandardError)

  def initialize(info, filename, preview_filename)
    @info = info
    @filename = filename
    @preview_filename = preview_filename
  end

  def upload
    video, preview = parse_info

    upload_file(video, @filename) if video
    upload_file(preview, @preview_filename)
  end

  private

  def upload_file(url, filename)
    `curl -fL '#{url}' --upload-file #{filename}`
  end

  def parse_info
    decoded = Base64.decode64(@info)

    schema = JSON.parse(
      decryptor.update(decoded) + decryptor.final,
      symbolize_names: true
    )

    [schema[:video], schema.fetch(:preview)]
  end

  def decryptor
    @decryptor ||= OpenSSL::Cipher.new('aes-256-cbc').decrypt.tap do |cipher|
      cipher.key = Digest::SHA256.digest('very_secret')
      cipher.iv = Digest::MD5.digest(File.basename(@filename))
    end
  end
end
# rubocop:enable Metrics/MethodLength,Style/FormatStringToken

filename = ARGV[0]
raise "#{filename} not found" unless File.exist?(filename)

info = VideoUploadInfo.new(filename)
begin
  body = info.request_body

  id = NewVideo.new(rubric_id: ARGV[1].to_i, uploaded_original: ARGV[2]).create(body)
  upload_info = UploadInfo.new(id).fetch

  VideoUploader.new(
    upload_info,
    filename,
    info.preview_file.path
  ).upload
ensure
  info.preview_file.close
  info.preview_file.unlink
end
