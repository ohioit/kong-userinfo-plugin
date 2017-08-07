return {
    no_consumer = true,
    fields = {
        ldap_host = {required = true, type = "string"},
        ldap_port = {required = true, type = "number"},
        bind_dn = {required = true, type="string"},
        bind_password = {require = true, type="string"},
        start_tls = {required = true, type = "boolean", default = false},
        base_dn = {required = true, type = "string"},
        search_filter = {required = true, type = "string", default = "cn={user}"},
        cache_ttl = {required = true, type = "number", default = 60},
        timeout = {type = "number", default = 10000},
        keepalive = {type = "number", default = 60000},
        attributes = {type = "array"}
    }
}
