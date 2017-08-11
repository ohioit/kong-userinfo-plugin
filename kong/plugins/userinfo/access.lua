local cache = require "kong.tools.database_cache"
local responses = require "kong.tools.responses"
local singletons = require "kong.singletons"
local printable_mt = require "kong.tools.printable"
local utils = require "kong.tools.utils"
local ldap = require "lua_ldap"

local ngx_get_headers = ngx.req.get_headers
local ngx_set_header = ngx.req.set_header
local ngx_re_gmatch = ngx.re.gmatch
local ldap_connect = ldap.open_simple
local base64_encode = ngx.encode_base64
local table_contains = utils.table_contains

local UPSTREAM_USERNAME_HEADER = "x-authenticated-userid"
local USERINFO_HEADER_BASENAME = "x-userinfo"
local LDAP_FILTER_USERNAME_VARIABLE = "{user}"
local LDAP_SEARCH_SCOPE = "subtree"
local CACHE_KEYS = {
    USERINFO_CACHE_KEY = "userinfo"
}

local _M = {}

local userinfo_key = function(username)
    return CACHE_KEYS.USERINFO_CACHE_KEY .. ":" .. username
end

local get_authenticated_user = function()
    return ngx_get_headers()[UPSTREAM_USERNAME_HEADER]
end

local convert_value
convert_value = function(name, value, conf)
    if type(value) == "table" then
        for i = 1, #value do
            value[i] = convert_value(name, value[i], conf)
        end
    else
        if table_contains(conf.convert_rdn_to_rdns, name) then
            converted = {}
            setmetatable(converted, printable_mt)
            for piece in ngx_re_gmatch(value, "=([^,]+),?", "jo") do
                piece = string.gsub(string.lower(piece[1]), "'", "\\'")

                if string.find(piece, "[ \\.]") then
                    piece = "'" .. piece .. "'"
                end

                if converted[1] ~= piece then
                    table.insert(converted, 1, piece)
                end
            end

            value = table.concat(converted, ".")
        end

        if table_contains(conf.encode_attributes, name) then
            return "=?UTF-8?B?" .. base64_encode(value) .. "?="
        end
    end

    return value
end

local load_userinfo = function(username, conf)
    local ldap, err = ldap_connect({
        uri = conf.ldap_uri,
        who = conf.bind_dn,
        password = conf.bind_password,
        starttls = conf.start_tls
    })

    if not ldap then
        return nil, "unable to connect to LDAP server " .. conf.ldap_uri .. ": " .. err
    end

    local result = nil
    local query = {
        attrs = conf.attributes,
        base = conf.base_dn,
        scope = LDAP_SEARCH_SCOPE,
        filter = string.gsub(conf.search_filter, LDAP_FILTER_USERNAME_VARIABLE, username),
        sizelimit = 2,
        timeout = conf.timeout
    }

    result = nil
    for dn, attributes in ldap:search(query) do
        if result then
            return nil,  "multiple entries for " .. username .. " found"
        end

        result = attributes
    end

    ldap:close()

    for key, value in pairs(result) do
        result[key] = convert_value(key, value, conf)
    end

    return result, nil
end

local get_header_name = function(field)
    return USERINFO_HEADER_BASENAME .. "-" .. field
end

local set_headers = function(userinfo)
    for name, value in pairs(userinfo) do
        if type(value) == "table" then
            value = table.concat(value, ",")
        end

        ngx_set_header(get_header_name(name), value)
    end
end

function _M.execute(conf)
    local user = get_authenticated_user()
    if user then
        local userinfo, err = cache.get_or_set(userinfo_key(user), conf.cache_ttl, load_userinfo, user, conf)

        if err then
            return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
        end

        if userinfo then
            set_headers(userinfo)
        end
    end

    return true
end

return _M
