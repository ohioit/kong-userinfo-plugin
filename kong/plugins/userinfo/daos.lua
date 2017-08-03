local cjson = require("cjson")

local function validate_json(v, t, column)
    if  v then
        if cjson.decode(v) then
            return true, nil
        else
            return false, "data is not valid json"
    end
end

local SCHEMA = {
    primary_key = {"id"},
    table = "userinfo_credentials"
    fields = {
        id = {type = "id", dao_insert_value = true},
        created_at = {type = "timestamp", immutable = true, dao_insert_value = true},
        credential_id = {type = "id", required = true}, foreign = "oauth2_credentials:id" },
        data = {type = "string", required = true, func = validate_json }
    },
    marshall_event = function(self, t)
        return { token = t.token_type .. ":" .. t.token }
    end
}

return {userinfo_credentials = SCHEMA}