-- /etc/nginx/lua/bw_check.lua
-- local key = ngx.var.args_upid or ngx.var.remote_addr
local upid = ngx.var.arg_upid
local today = os.date("%Y-%m-%d")   -- e.g. 2026-07-02
local host = ngx.var.host

local limit = 30 * 1024 * 1024 * 1024  -- 30 GB
local key = host .. ":" .. today .. ":" .. upid

if not key or key == "" then
    -- return ngx.exit(ngx.HTTP_FORBIDDEN)
end



local bw = ngx.shared.bw_counters
local used = bw:get(key) or 0


-- if used > limit and ngx.var.arg_token == 'yri2KZXKARh9TtGz-JwFbA' then
-- if used > limit and ngx.var.arg_upid == '4ba1ca0fac1f054be9b99e55575fe1e4' then
if used > limit then
    ngx.exit(403)
end
