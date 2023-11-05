{ name, config, pkgs, ... }:
{
  age.secrets.restic-password.file = ../../secrets/general/restic-password.age;
  services.restic.backups = {
    "remote-backup" = {
        initialize = true;
        passwordFile = config.age.secrets.restic-password.path;
        paths = [
            
        ];
    };
  };
}