local events  = require "kong.core.events"
local cache = require "kong.tools.database_cache"

local function invalidate_on_update(message_t)
    if message_t.collection == "oauth2_tokens" then
        cache.delete("userinfo." .. message_t.old_entity.authenticated_userid)
    end
end

local function invalidate_on_create(message_t)
    if message_t.collection == "oauth2_tokens" then
        cache.delete("userinfo." .. message_t.entity.authenticated_userid)
    end
end

return {
    [events.TYPES.ENTITY_UPDATED] = function(message_t)
        invalidate_on_update(message_t)
    end,
    [events.TYPES.ENTITY_DELETED] = function(message_t)
        invalidate_on_create(message_t)
    end
}
