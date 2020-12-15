# frozen_string_literal: true

if @success
  json.id @model.id
else
  @model.errors.each do |error|
    json.set! error.attribute, error.message
  end
end
