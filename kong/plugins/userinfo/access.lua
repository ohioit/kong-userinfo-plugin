local cache = require "kong.tools.database_cache"
local responses = require "kong.tools.responses"
local singletons = require "kong.singletons"
local printable_mt = require "kong.tools.printable"
local ldap = require "lua_ldap"

local ngx_get_headers = ngx.req.get_headers
local ngx_set_header = ngx.req.set_header
local ldap_connect = ldap.open_simple

local USERINFO_HEADER_BASENAME = "x-userinfo"
local CACHE_KEYS = {
    USERINFO_CACHE_KEY = "userinfo_credentials"
}

local _M = {}

local userinfo_key = function(username)
    return CACHE_KEYS.USERINFO_CACHE_KEY .. ":" .. username
end

local get_authenticated_user = function()
    return ngx_get_headers()['authenticated_userid']
end

local load_userinfo = function(username, conf)
    local uri = "ldap"

    if conf.start_tls then
        uri = uri .. "s"
    end

    uri = uri .. "://" .. conf.ldap_host .. ":" .. conf.ldap_port

    ngx.log(ngx.DEBUG, "Connecting to", uri)
    local ldap = ldap_connect({
        uri = uri,
        who = conf.bind_dn,
        password = conf.bind_password,
        starttls = conf.start_tls
    })

    if not ldap then
        return nil, "unable to connect to LDAP server " .. uri
    end

    local result = nil
    local query = {
        attrs = conf.attributes.split(","),
        base = conf.base_dn,
        filter = conf.search_filter.gsub("{user}", username),
        sizelimit = 2,
        timeout = conf.timeout
    }
    setmetatable(query, printable_mt)
    ngx.log(ngx.DEBUG, "Searching for ", query)
    for dn, attributes in ldap:search(query) do
        if result then
            return nil,  "multiple entries for " .. username .. " found"
        end

        result = attributes
    end

    ldap:close()

    return result, nil
end

local get_header_name = function(field)
    return USERINFO_HEADER_BASENAME .. "-" .. field
end

local set_headers = function(userinfo)
    for name, value in pairs(userinfo) do
        if type(value) == "table" then
            value = string.join(table, ",")
        end

        ngx.log(ngx.DEBUG, "Setting header ", name, " to ", value)
        ngx_set_header(get_header_name(name), value)
    end
end

function _M.execute(conf)
    local user = get_authenticated_user()
    if user then
        ngx.log(ngx.DEBUG, "Got authenticated user: ", user)

        local userinfo, err = cache.get_or_set(userinfo_key(user), nil, load_userinfo, user, conf)

        if err then
            return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
        end

        if userinfo then
            ngx.log(ngx.DEBUG, "Loaded user info: ", userinfo)
            set_headers(userinfo)
        end
    else
        ngx.log(ngx.DEBUG, "No user authenticated.")
    end

    return true
end

return _M
