if @success
  json.id @track.id
else
  @track.errors.each do |attr, value|
    json.set! attr, value
  end
end
