{ pkgs, config, ... }: 
let mastConfig = config.services.mastodon;
in {
  services = {
    postgresqlBackup = {
      enable = true;
      compression = "zstd";
      databases = [ mastConfig.database.name ];
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
