local BasePlugin = require "kong.plugins.base_plugin"
local UserinfoHandler = BasePlugin:extend()

function UserinfoHandler:new()
    UserinfoHandler.super.new(self, "userinfo-plugin")
end

function UserinfoHandler:access(config)
    UserinfoHandler.super.access(self)
end

return UserinfoHandler