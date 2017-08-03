local cache = require "kong.tools.database_cache"
local responses = require "kong.tools.responses"
local singletons = require "kong.singletons"
local cjson = require "cjson"

local json_decode = cjson.decode
local ngx_set_header = ngx.req.set_header

local USERINFO_HEADER_BASENAME = "x-userinfo"
local CACHE_KEYS = {
    USERINFO_CACHE_KEY = "userinfo_credentials"
}

local _M = {}

local userinfo_key = function(credential_id)
    return CACHE_KEYS.USERINFO_CACHE_KEY .. ":" .. credential_id
end

local simplify_userinfo = function(userinfo)
    simpleinfo = {}

    if userinfo.memberof then
        simpleinfo.groups = table.concat(userinfo.memberof, ",")
    end
    
    return simpleinfo
end

local load_userinfo = function(credential_id)
    local userinfo, err = dao.userinfo.credentials:find_all({ credential_id = credential_id })

    if err then
        return nil, err
    end

    return simplify_userinfo(userinfo[1])
end

local get_header_name(field)
    return USERINFO_HEADER_BASENAME .. "-" .. field
end

local set_headers = function(userinfo)
    for name, value in pairs(userinfo) do
        ngx.log(ngx.DEBUG, "Setting header ", name, " to ", value)
        ngx_set_header(get_header_name(name), value)
    end
end

function _M.execute(conf)
    local credential = ngx.ctx.authenticated_credential
    if ngx.ctx.authenticated_credential then
        ngx.log(ngx.DEBUG, "Got authenticated credential: ", credential)

        local userinfo, err = cache.get_or_set(userinfo_key(credential.id), nil, load_userinfo, credential.id)

        if err then
            return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
        end

        if userinfo then
            ngx.log(ngx.DEBUG, "Loaded user info: ", userinfo)
            userinfo = json_decode(userinfo)
            set_headers(userinfo)
        end
    end

    return true
end

return _M