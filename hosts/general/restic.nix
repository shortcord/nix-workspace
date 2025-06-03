{ name, config, pkgs, lib, ... }:
let
  serviceConf = config.services;
  enableJob = (serviceConf.mysqlBackup.enable || serviceConf.postgresqlBackup.enable );
in {
  age.secrets = lib.mkIf (enableJob) {
    restic-password.file = ../../secrets/general/restic-password.age;
    restic-s3-env.file = ../../secrets/general/restic-s3-env.age;
  };
  services.restic.backups = {
    "remote-backup" = lib.mkIf (enableJob) {
        initialize = true;
        passwordFile = config.age.secrets.restic-password.path;
        environmentFile = config.age.secrets.restic-s3-env.path;
        repository = "s3:storage.owo.systems/shortcord-backups/restic/${config.networking.fqdn}";
        paths = lib.mkMerge [
          (lib.mkIf (serviceConf.mysqlBackup.enable) [ serviceConf.mysqlBackup.location ] )
          (lib.mkIf (serviceConf.postgresqlBackup.enable) [ serviceConf.postgresqlBackup.location ] )
        ];
    };
  };
}