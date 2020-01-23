# frozen_string_literal: true

json.array!(@resources) do |resource|
  json.(resource[:token], :id, :login)
  json.type resource[:type]
end
