{ pkgs, config, ... }: {
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
  services = {
    deluge = {
      enable = true;
      declarative = true;
      web = { enable = true; };
      config = {
        torrentfiles_location = "/var/lib/deluge/torrentfiles";
        download_location = "/var/lib/deluge/downloaded";
        torrentfiles_location = "/var/lib/deluge/torrentfiles";
      };
    };
    nginx = {
      virtualHosts = {
        "deluged.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = { proxyPass = "http://127.0.0.1:8112"; };
        };
      };
    };
  };
}
