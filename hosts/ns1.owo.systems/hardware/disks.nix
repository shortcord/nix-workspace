{
  name,
  pkgs,
  lib,
  config,
  ...
}:
{
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      autoResize = true;
      fsType = "ext4";
    };
  };
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              label = "NIXBOOT";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              label = "NIXROOT";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
