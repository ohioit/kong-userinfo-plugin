package = "kong-plugin-userinfo"
version = "0.0.1-1"
supported_platforms = {"linux", "macosx"}
description = {
    summary = "Kong Userinfo Plugin",
    detailed = [[
        Allow provisioning detailed user info and adding it
        to request headers for upstream APIs.
    ]]
}
dependencies  = {}

local pluginName = "userinfo"
build = {
    type = "builtin",
    modules = {
        ["kong.plugins."..pluginName..".migrations.cassandra"] = "kong/plugins/"..pluginName.."/migrations/cassandra.lua",
        ["kong.plugins."..pluginName..".migrations.postgres"] = "kong/plugins/"..pluginName.."/migrations/postgres.lua",
        ["kong.plugins."..pluginName..".api"] = "kong/plugins/"..pluginName.."/access.lua",
        ["kong.plugins."..pluginName..".api"] = "kong/plugins/"..pluginName.."/api.lua",
        ["kong.plugins."..pluginName..".daos"] = "kong/plugins/"..pluginName.."/daos.lua",
        ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
        ["kong.plugins."..pluginName..".hooks"] = "kong/plugins/"..pluginName.."/hooks.lua",
        ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua"
    }
}
