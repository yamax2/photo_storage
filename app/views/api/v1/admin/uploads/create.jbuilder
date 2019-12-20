# frozen_string_literal: true

if @success
  json.id @model.id
else
  @model.errors.each do |attr, value|
    json.set! attr, value
  end
end
