return {
    {
        name = "2017-08-02-155600_init_userinfo",
        up = [[
            CREATE TABLE IF NOT EXISTS userinfo_credentials(
                id uuid,
                created_at timestamp,
                credential_id uuid,
                data text,
                PRIMARY KEY(id)
            );

            CREATE INDEX IF NOT EXISTS userinfo_credential_id_idx ON userinfo_credentials(credential_id);
        ]],
        down = [[
            DROP TABLE userinfo_credentials;
        ]]
    }
}
