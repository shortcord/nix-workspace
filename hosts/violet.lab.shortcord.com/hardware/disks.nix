{ name, pkgs, lib, config, ... }: {
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/4b837b12-69c1-4e4e-8a97-9dd38fdba342";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2C1D-95D4";
      fsType = "vfat";
    };
    "/btrfs" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
      ];
    };
    "/var/lib/docker" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=257"
      ];
    };
    "/var/lib/libvirt/images/pool" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=741"
      ];
    };
    "/var/lib/jellyfin/transcodes" = {
      fsType = "tmpfs";
      options = [
        "size=10g"
        "mode=0700"
        "gid=983"
        "uid=990"
      ];
    };
  };
}
