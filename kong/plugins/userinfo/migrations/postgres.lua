return {
    {
        name = "2017-08-02-155600_init_userinfo",
        up = [[
            CREATE TABLE IF NOT EXISTS userinfo_credentials(
                id uuid,
                created_at timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
                credential_id uuid REFERENCES oauth2_credentials (id) ON DELETE CASCADE
                data text,
                PRIMARY KEY(id)
            );

            DO $$
            BEGIN
                IF (SELECT to_regclass('public.userinfo_credential_id_idx')) IS NULL THEN
                    CREATE INDEX userinfo_credential_id_idx ON userinfo_credentials(credential_id);
                END IF;
            END$$;
        ]],
        down = [[
            DROP TABLE userinfo_credentials;
        ]]
    }
}