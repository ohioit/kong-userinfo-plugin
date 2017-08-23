return {
    no_consumer = true,
    fields = {
        ldap_uri = {required = true, type = "url"},
        bind_dn = {required = true, type="string"},
        bind_password = {required = true, type="string"},
        start_tls = {required = true, type = "boolean", default = false},
        base_dn = {required = true, type = "string"},
        search_filter = {required = true, type = "string", default = "cn={user}"},
        cache_ttl = {required = true, type = "number", default = 60},
        timeout = {type = "number", default = 10000},
        attributes = {required = true, type = "array"},
        encode_attributes = {required = false, type="array"},
        convert_rdn_to_rdns = {required = false, type="array"},
        deny_unknown_users = {required = true, type="boolean", default = false}
    }
}
