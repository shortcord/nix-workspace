{ pkgs, config, ... }: {
  services = {
    postgresqlBackup = {
      enable = true;
      compression = "zstd";
      databases = [ config.services.mastodon.database.name ];
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ mastConfig.database.name ];
      ensureUsers = [{
        name = mastConfig.database.user;
        ensureDBOwnership = true;
      }];
    };
  };
}
