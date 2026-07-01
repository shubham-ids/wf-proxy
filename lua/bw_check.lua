-- /etc/nginx/lua/bw_check.lua
local key = ngx.var.arg_token or ngx.var.remote_addr
local limit = 0.4 * 1024 * 1024 * 1024  -- 5GB

local bw = ngx.shared.bw_counters
local used = bw:get(key) or 0

ngx.var.used = tostring(used)
ngx.header["X-Second-Used"] = tostring(used)
ngx.header["X-Second-ngx.var.bytes_sent"] = ngx.var.bytes_sent


if used > limit and ngx.var.arg_token == 'b4V0P9LlKLb5MWdK4zRCwA' then
    ngx.header["X-Limit-Reached-Used"] = tostring(used)
    ngx.header["X-Limit-Reached-ngx.var.remote_addr"] = ngx.var.remote_addr
    ngx.header["X-Limit-Reached-ngx.var.arg_token"] = ngx.var.arg_token
    -- ngx.exit(403)
end
