-- local common libs
local require     = require
local ipairs      = ipairs
local ngx_re_gsub = ngx.re.gsub
local core        = require("apisix.core")

-- module define
local plugin_name = "data-mask"

-- plugin schema
local plugin_schema = {
    type = "object",
    properties = {
        rules = {
            type = "array",
            items = {
                type = "object",
                properties = {
                    regex = {
                        type = "string",
                        minLength = 1,
                    },
                    replace = {
                        type = "string",
                    },
                },
                required = {
                    "regex",
                    "replace",
                },
                additionalProperties = false,
            },
            minItems = 1,
        },
    },
    required = {
        "rules",
    },
}

local _M = {
    version  = 0.1,            -- plugin version
    priority = 0,              -- the priority of this plugin will be 0
    name     = plugin_name,    -- plugin name
    schema   = plugin_schema,  -- plugin schema
}


-- module interface for schema check
-- @param `conf` user defined conf data
-- @param `schema_type` defined in `apisix/core/schema.lua`
-- @return <boolean>
function _M.check_schema(conf, schema_type)
    return core.schema.check(plugin_schema, conf)
end


-- module interface for header_filter phase
function _M.header_filter(conf, ctx)
    core.response.clear_header_as_body_modified()
end


-- module interface for body_filter phase
function _M.body_filter(conf, ctx)
    local body = core.response.hold_body_chunk(ctx)
    if not body then
        return
    end

    for _, rule in ipairs(conf.rules) do
        body = ngx_re_gsub(body, rule.regex, rule.replace, "jo")
    end

    ngx.arg[1] = body
    ngx.arg[2] = true
end

return _M