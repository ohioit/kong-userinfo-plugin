local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.userinfo.access"

local UserinfoHandler =  BasePlugin:extend()

function  UserinfoHandler:new()
    UserinfoHandler.super.new(self, "userinfo")
end

function UserinfoHandler:access(conf)
    UserinfoHandler.super.access(self)
    access.execute(conf)
end

return UserinfoHandler