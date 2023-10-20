{ pkgs, config, ... }:
{
    services = {
        postgresqlBackup = {
            enable = true;
            compression = "zstd";
            databases = [
                config.services.mastodon.database.name
                "matrix_synapse"
            ];
        };
        postgresql = {
            enable = true;
            ensureDatabases = [
                config.services.mastodon.database.name
                "matrix_synapse"
            ];
            ensureUsers = [
                {
                    name = config.services.mastodon.database.user;
                    ensurePermissions = {
                        "DATABASE ${config.services.mastodon.database.name}" = "ALL PRIVILEGES";
                    };
                }
                {
                    name = "matrix_synapse";
                    ensurePermissions = {
                        "DATABASE matrix_synapse" = "ALL PRIVILEGES";
                    };
                }
            ];
        };
    };
}