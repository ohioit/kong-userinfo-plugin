local responses = require "kong.tools.responses"
local singletons = require "kong.singletons"
local utils = require "kong.tools.utils"
local ldap = require "lua_ldap"
local pl_stringx = require "pl.stringx"

local ngx_get_headers = ngx.req.get_headers
local ngx_set_header = ngx.req.set_header
local ngx_clear_header = ngx.req.clear_header
local ngx_re_gmatch = ngx.re.gmatch
local unescape_uri = ngx.unescape_uri
local ldap_connect = ldap.open_simple
local base64_encode = ngx.encode_base64
local table_contains = utils.table_contains
local str_replace = pl_stringx.replace

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
    return unescape_uri(ngx_get_headers()[UPSTREAM_USERNAME_HEADER])
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

            for piece in ngx_re_gmatch(value, "=([^,]+),?", "jo") do
                piece = string.gsub(string.lower(piece[1]), " ", "-")

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
        filter = str_replace(conf.search_filter, LDAP_FILTER_USERNAME_VARIABLE, username),
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

    if not result then
        return nil, nil
    end

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
    local headers = ngx_get_headers()

    for i = 1, #headers do
        if string.sub(headers[i],1,#USERINFO_HEADER_BASENAME) == USERINFO_HEADER_BASENAME then
            ngx_clear_header(headers[i])
        end
    end

    local user = get_authenticated_user()
    if user then
        local opts = {
            ttl = conf.cache_ttl,
            neg_ttl = conf.cache_ttl
        }
        local userinfo, err = singletons.cache:get(userinfo_key(user), opts, load_userinfo, user, conf)

        if err then
            return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
        end

        if userinfo then
            set_headers(userinfo)
        elseif conf.deny_unknown_users then
            return responses.send_HTTP_FORBIDDEN()
        end
    end

    return true
end

return _M
