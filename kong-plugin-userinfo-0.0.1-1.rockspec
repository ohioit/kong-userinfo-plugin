local pluginName = "userinfo"

package = "kong-plugin-" .. pluginName
version = "0.0.1-1"
supported_platforms = {"linux", "macosx"}
source = {
    url = "git@github.com:ohioit/kong-" .. pluginName .. "-plugin.git"
}
description = {
    summary = "Kong Userinfo Plugin",
    detailed = [[
        Allow provisioning detailed user info and adding it
        to request headers for upstream APIs.
    ]]
}
dependencies  = {
    "lua_ldap >= 1.0.2"
}
build = {
    type = "builtin",
    modules = {
        ["kong.plugins."..pluginName..".access"] = "kong/plugins/"..pluginName.."/access.lua",
        ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
        ["kong.plugins."..pluginName..".hooks"] = "kong/plugins/"..pluginName.."/hooks.lua",
        ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua"
    }
}
