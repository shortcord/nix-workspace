{ name, config, pkgs, lib, ... }:
{
  age.secrets = {
    restic-password.file = ../../secrets/general/restic-password.age;
    restic-s3-env.file = ../../secrets/general/restic-s3-env.age;
  };
  services.restic.backups = {
    "remote-backup" = {
        initialize = true;
        passwordFile = config.age.secrets.restic-password.path;
        environmentFile = config.age.secrets.restic-s3-env.path;
        repository = "s3:storage.owo.systems/shortcord-backups/restic/${config.networking.fqdn}";
        paths = lib.mkMerge [
          (lib.mkIf (config.services.mysqlBackup.enable) [ config.services.mysqlBackup.location ] )
          (lib.mkIf (config.services.postgresqlBackup.enable) [ config.services.postgresqlBackup.location ] )
        ];
    };
  };
}