# frozen_string_literal: true

namespace :gpx do
  task :import, [:host, :dbname, :user, :default_rubric_id] => :environment do |_, args|
    pg = PG.connect(
      dbname: args.fetch(:dbname, 'gpx'),
      host: args.fetch(:host, 'db'),
      user: args.fetch(:user, 'postgres')
    )

    SQL = <<~SQL
      SELECT i.id, i.name, i.created_at, t.name track_name, t.code, i.data 
        FROM track_items i, tracks t 
          WHERE t.code = i.track_code 
            ORDER BY i.id
    SQL

    found = 0
    total = 0

    default_rubric =
      if (default_rubric_id = args['default_rubric_id']).present?
        Rubric.find(default_rubric_id)
      else
        Rubric.first
      end

    table = Rubric.arel_table
    dir = Rails.root.join('tmp/gpx')
    FileUtils.mkdir_p(dir)

    pg.exec(SQL).each do |row|
      next if Track.where(external_info: row['id']).exists?

      rubric = Rubric.where(table[:description].matches("%#{row['code']}%")).first
      found += 1 if rubric
      rubric ||= default_rubric

      local_file = dir.join("#{row['id']}.gpx")
      File.open(local_file, 'wb') do |file|
        file.write(row['data'])
      end

      uploaded_io = ActionDispatch::Http::UploadedFile.new(
        filename: "#{row['id']}.gpx",
        type: Track::MIME_TYPE,
        tempfile: File.open(local_file)
      )

      track = Track.new(
        rubric: rubric,
        external_info: row['id'],
        name: "#{row['track_name']} - #{row['name']}".strip
      )

      ::Tracks::EnqueueProcessService.call!(model: track, uploaded_io: uploaded_io)

      total += 1
      puts row['id']
      FileUtils.rm_f(local_file)
    end

    puts "#{found} / #{total}"
    puts "default rubric is #{default_rubric.id}"
  end
end
