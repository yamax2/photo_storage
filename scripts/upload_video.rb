#!/usr/bin/env ruby
# frozen_string_literal: true

# Warning! Still not for a production!
#
# Arguments:
#   * original video, required
#   * rubric_id, required)
#   * temporary uploaded, optional
#
# apt install mediainfo curl ffmpeg
# $ cat ~/.photostorage
# host: "http://11.0.2.5"
# auth: "admin:..."
# secret: "very_secret"

require 'json'
require 'tempfile'
require 'date'
require 'open3'
require 'digest'
require 'openssl'
require 'base64'
require 'yaml'

# rubocop:disable Metrics/MethodLength,Style/FormatStringToken
Conf = Struct.new(:host, :secret, :auth) do
  def load!
    config = "#{ENV['HOME']}/.photostorage"

    raise "Config file not found #{config}" unless File.exist?(config)

    mode = File.stat(config).mode & 0o7777

    raise "Config file #{config} should have permissions 0600" unless mode == 0o600

    configuration = YAML.load_file(config).slice('host', 'auth', 'secret')

    self.host = configuration.fetch('host')
    self.secret = configuration.fetch('secret')
    self.auth = configuration['auth']
  end
end.new

# ffmpeg -i 12.mp4 -vf scale=1920:1080 -c:v libx264 -c:a copy -crf 25 12a.mp4
# fails on < 1080
class VideoMetadata
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

  def video_preview_file
    @video_preview_file ||= Tempfile.new(['preview', File.extname(@filename)]).tap do |file|
      make_video_preview(file.path)
    end
  end

  def request_body
    return @request_body if defined?(@request_body)

    general, video = parse_media_info

    @request_body = upload_request_body(general, video)
  end

  private

  def upload_request_body(general, video) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    name = File.basename(filename)
    lat_long = general.dig(:extra, :xyz) || general.dig(:extra, :location)

    make = general.dig(:extra, :com_android_manufacturer)
    model = general.dig(:extra, :com_android_model)

    dimensions = [video.fetch(:Width).to_i, video.fetch(:Height).to_i]
    dimensions.reverse! if [90, 270].include?(video[:Rotation].to_i)

    {
      name: File.basename(name, '.*'),
      original_filename: name,
      original_timestamp: parse_timestamp(general[:Tagged_Date] || general[:Encoded_Date]),
      width: dimensions.first,
      height: dimensions.last,
      content_type: CONTENT_TYPES_BY_EXT.fetch(general.fetch(:FileExtension)),
      lat_long: lat_long ? lat_long.gsub(/[^0-9.]/, ' ').to_s.strip.split.map(&:to_f) : nil,
      md5: md5(filename),
      sha256: sha256(filename),
      size: general[:FileSize].to_i,
      preview_md5: md5(preview_file.path),
      preview_sha256: sha256(preview_file.path),
      preview_size: preview_file.size,
      video_preview_md5: md5(video_preview_file.path),
      video_preview_sha256: sha256(video_preview_file.path),
      video_preview_size: video_preview_file.size,
      duration: video.fetch(:Duration).to_f,
      tz: @timezone,
      exif: make && model ? {make: model, model: model} : nil
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

  def make_video_preview(path)
    `ffmpeg -y -i #{filename} -vf scale="trunc(oh*a/2)*2:1080" -c:v libx264 -c:a copy -crf 25 #{path}`
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
    "curl -sL -w '|%{http_code}' '#{Conf.host}/api/v1/admin/videos' -u \"#{Conf.auth}\"" \
      " -H 'Content-Type: application/json'" \
      " -d '{\"temporary_uploaded_filename\": \"#{uploaded_original}\", \"video\": #{request_body.to_json}'}"
  end
end

class UploadInfo
  NotFetchedError = Class.new(StandardError)

  attr_reader :id

  def initialize(id, filename, attempts: 10)
    @id = id
    @filename = filename
    @attempts = attempts
  end

  def fetch
    response = nil

    @attempts.times do
      response, _, status = Open3.capture3("curl -sfL -u \"#{Conf.auth}\" '#{Conf.host}/api/v1/admin/videos/#{id}'")

      break if status.success?

      sleep 1
    end

    raise NotFetchedError, "info fetch failed for video #{id}" if response&.empty?

    parse_info(response)
  end

  private

  def parse_info(info)
    decoded = Base64.decode64(info)

    schema = JSON.parse(
      decryptor.update(decoded) + decryptor.final,
      symbolize_names: true
    )

    [schema[:video], schema.fetch(:preview), schema.fetch(:video_preview)]
  end

  def decryptor
    @decryptor ||= OpenSSL::Cipher.new('aes-256-cbc').decrypt.tap do |cipher|
      cipher.key = Digest::SHA256.digest(Conf.secret)
      cipher.iv = Digest::MD5.digest(File.basename(@filename))
    end
  end
end

class VideoUploader
  NotUploadedError = Class.new(StandardError)

  def initialize(info, filename, preview_filename, video_preview_filename)
    @info = info

    @filename = filename
    @preview_filename = preview_filename
    @video_preview_filename = video_preview_filename
  end

  def upload
    video, preview, video_preview = @info

    upload_file(video, @filename) if video
    upload_file(preview, @preview_filename)
    upload_file(video_preview, @video_preview_filename)
  end

  private

  def upload_file(url, filename)
    `curl -fL '#{url}' --upload-file #{filename}`
  end
end
# rubocop:enable Metrics/MethodLength,Style/FormatStringToken

filename = ARGV[0]
raise "#{filename} not found" unless File.exist?(filename)

Conf.load!

meta = VideoMetadata.new(filename)
begin
  body = meta.request_body

  id = NewVideo.new(rubric_id: ARGV[1].to_i, uploaded_original: ARGV[2]).create(body)
  upload_info = UploadInfo.new(id, filename).fetch

  VideoUploader.new(
    upload_info,
    filename,
    meta.preview_file.path,
    meta.video_preview_file.path
  ).upload
ensure
  meta.preview_file.close
  meta.preview_file.unlink

  meta.video_preview_file.close
  meta.video_preview_file.unlink
end
