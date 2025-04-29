{ name, pkgs, lib, config, ... }:
let
  webRoot = "/var/repo-mirrors";
  dlDirectory = "${webRoot}/archlinux";
  upstream = "rsync://mirrors.edge.kernel.org/archlinux/";
in {
  security.acme.certs."repos.${config.networking.fqdn}" = {
    inheritDefaults = true;
    dnsProvider = "pdns";
    environmentFile = config.age.secrets.acmeCredentialsFile.path;
    webroot = null;
  };

  fileSystems = {
    "/var/repo-mirrors" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=926"
      ];
    };
  };

  systemd = {
    timers = {
      "repo-sync-arch-process" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnActiveSec = "1d";
          OnUnitActiveSec = "1d";
          Unit = "repo-sync-arch-process.service";
        };
      };
    };
    services = {
      repo-sync-arch-process = {
        after = [ "network.target" "repo-sync-arch-init-dirs.service" ];
        requires = [ "repo-sync-arch-init-dirs.service" ];
        script = ''
          set -eu

          ${pkgs.flock}/bin/flock -n /tmp/repo-sync-arch-process.lockfile \
            ${pkgs.rsync}/bin/rsync \
              -PrltH -4 --safe-links --no-motd --delete-delay --delay-updates \
              "${upstream}" \
              "${dlDirectory}"

          exit 0
        '';
        serviceConfig = {
          Type = "oneshot";
          SyslogIdentifier = "repo-sync-arch-process";
        };
      };
      repo-sync-arch-init-dirs = {
        after = [ "network.target" ];
        script = ''
          mkdir -p "${dlDirectory}"
        '';
        serviceConfig = {
          Type = "oneshot";
          SyslogIdentifier = "repo-sync-arch-init-dirs";
        };
      };
    };
  };
  services.nginx = {
    virtualHosts = {
      "repos.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;

        root = webRoot;

        locations = {
          "/" = {
            tryFiles = " $uri $uri/ $uri.html =404";
            extraConfig = ''
              autoindex on;
            '';
          };
        };
      };
    };
  };
}
