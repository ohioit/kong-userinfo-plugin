local crud = require "kong.api.crud_helpers"

return {
    before = function(self,  dao_factory, helpers)
        local dao = dao_factory.oauth2_authorization_code
        local authorization, err = dao:find_all({ code = self.params.code })

        if err then
            return helpers.yield_error(err)
        elseif next(authorization) == nil then
            return helpers.response.send_HTTP_NOT_FOUND()
        end

        self.credential_id = authorization[0].credential_id
    end,
    ["/userinfo/provision"] = {
        POST = function(self, dao_factory, helpers)
            crud.post({
                credential_id = self.credential_id,
                data = self.req.get_body_data(),
            }, dao_factory.userinfo_credentials)
        end
    }
}
