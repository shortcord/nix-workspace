{ name, pkgs, config, lib, ... }: {
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
      group = "users";
      declarative = true;
      web = {
        enable = true;
        openFirewall = false;
      };
      authFile = config.age.secrets.deluged.path;
      config = {
        torrentfiles_location = "/var/lib/deluge/torrentfiles";
        download_location = "/var/lib/deluge/downloaded";
        allow_remote = true;
        enabled_plugins = [ "Label" ];
        stop_seed_ratio = 0;
        stop_seed_at_ratio = true;
        share_ratio_limit = 0;
        max_active_seeding = 0;
        max_active_downloading = 10;
        max_active_limit = 10;
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
          locations."/" = {
            proxyPass = "http://127.0.0.1:8112";
          };
        };
      };
    };
  };
  systemd.services.deluged = {
    serviceConfig = {
      UMask = lib.mkForce "0013";
    };
  };
}
