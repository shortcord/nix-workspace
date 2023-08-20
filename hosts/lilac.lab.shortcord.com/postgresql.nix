{ pkgs, config, ... }:
{
    services = {
        postgresqlBackup = {
            enable = true;
            compression = "zstd";
            databases = [
                config.services.mastodon.database.name
            ];
        };
        postgresql = {
            enable = true;
            ensureDatabases = [
                config.services.mastodon.database.name
            ];
            ensureUsers = [
                {
                    name = config.services.mastodon.database.user;
                    ensurePermissions = {
                        "DATABASE ${config.services.mastodon.database.name}" = "ALL PRIVILEGES";
                    };
                }
            ];
        };
    };
}