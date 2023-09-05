{ name, pkgs, config, ... }: {
  age.secrets.deluged = {
    file = ../../secrets/${name}/deluged.age;
    owner = config.services.deluge.user;
    group = config.services.deluge.group;
  };
  fileSystems = {
    "/var/lib/deluge" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=921"
      ];
    };
  };
  networking.firewall = {
    allowedTCPPorts = [ 58846 ];
    allowedUDPPorts = [ 58846 ];
  };
  services = {
    deluge = {
      enable = true;
      declarative = true;
      web = { enable = false; };
      authFile = config.age.secrets.deluged.path;
      config = {
        torrentfiles_location = "/var/lib/deluge/torrentfiles";
        download_location = "/var/lib/deluge/downloaded";
        allow_remote = true;
      };
    };
  };
}
