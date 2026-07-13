local bw = ngx.shared.bw_counters

ngx.header.content_type = "application/json"

local keys = bw:get_keys(0) -- 0 = all keys
local result = {}

for _, key in ipairs(keys) do
    local bytes = bw:get(key) or 0

    local value
    if bytes >= 1024 * 1024 * 1024 then
        value = string.format("%.2f GB", bytes / (1024 * 1024 * 1024))
    elseif bytes >= 1024 * 1024 then
        value = string.format("%.2f MB", bytes / (1024 * 1024))
    elseif bytes >= 1024 then
        value = string.format("%.2f KB", bytes / 1024)
    else
        value = string.format("%d B", bytes)
    end

    table.insert(result, {
        upid = key,
        bytes = bytes,
        usage = value
    })
end

table.sort(result, function(a, b)
    return a.bytes > b.bytes
end)

-- 
ngx.say(require("cjson").encode(result))
