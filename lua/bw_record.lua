-- /etc/nginx/lua/bw_record.lua
local upid = ngx.var.arg_upid
local today = os.date("%Y-%m-%d")   -- e.g. 2026-07-02
local host = ngx.var.host

-- local bytes = tonumber(ngx.var.body_bytes_sent) or 0
local bytes = tonumber(ngx.var.body_bytes_sent)
if not bytes then
    bytes = tonumber(ngx.var.upstream_bytes_received) or 0
end

local key = host .. ":" .. today .. ":" .. upid

local bw = ngx.shared.bw_counters
bw:incr(key, bytes, 0, 7 * 24 * 60 * 60);

-- ngx.header["X-Second-ngx-a"] = tostring(ngx.var.upstream_bytes_received)
-- ngx.header["X-Second-ngx-b"] = tostring(ngx.var.upstream_http_content_length)
-- ngx.header["X-Second-ngx-c-byte"] = tostring(bytes)
-- ngx.header["X-Second-ngx-c-body_bytes_sent"] = tonumber(ngx.var.body_bytes_sent)
-- ngx.header["X-Second-ngx-d"] = "Tes"

-- ngx.log(ngx.ERR, "LOG FIRED uri=", ngx.var.uri, 
--     " bytes_sent=", ngx.var.bytes_sent,
--     " body_bytes_sent=", ngx.var.body_bytes_sent)

-- ngx.log(ngx.ERR, "New LOG FIRED uri=", ngx.var.uri,
--         " upstream_bytes_received=", ngx.var.upstream_bytes_received,
--         " upstream_http_content_length=", ngx.var.upstream_http_content_length)

