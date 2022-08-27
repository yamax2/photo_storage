local cache_values = redis.call("HGETALL", KEYS[1])
local cache = {}

for idx = 1, #cache_values, 2 do
  cache[cache_values[idx]] = cache_values[idx + 1]
end

local info = cjson.decode(ARGV[1])
local result = {}

for id, space in pairs(info) do
  local current_space = cache[id] or 0

  current_space = current_space + ARGV[2]
  if current_space < space then
    table.insert(result, id)
  end
end

if table.getn(result) > 0 then
  local id = math.min(unpack(result))
  redis.call("HINCRBY", KEYS[1], id, ARGV[2])

  return id
end
