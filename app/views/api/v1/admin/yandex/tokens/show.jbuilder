# frozen_string_literal: true

json.(@token, :id, :login, :folder_index)
json.info @info

json.size @token.public_send(:"#{@resource}_size").to_i
json.count @token.public_send(:"#{@resource}_count").to_i
