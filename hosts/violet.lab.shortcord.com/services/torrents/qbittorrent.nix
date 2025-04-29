{ name, pkgs, config, lib, ... }: {
  security.acme.certs."qbittorrent.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
  fileSystems = {
    "/var/lib/qbittorrent" = {
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
    nginx = {
      virtualHosts = {
        "qbittorrent.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8082"; };
        };
      };
    };
  };

  systemd.services.qbittorrent = {
    # based on the plex.nix service module and
    # https://github.com/qbittorrent/qBittorrent/blob/master/dist/unix/systemd/qbittorrent-nox%40.service.in
    description = "qBittorrent-nox service";
    documentation = [ "man:qbittorrent-nox(1)" ];
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    unitConfig = {
      RequiresMountsFor = [ "/var/lib/qbittorrent" ];
    };

    serviceConfig = {
      Type = "simple";
      User = "qbittorrent";
      Group = "torrents";

      # Run the pre-start script with full permissions (the "!" prefix) so it
      # can create the data directory if necessary.
      ExecStartPre = let
        preStartScript = pkgs.writeScript "qbittorrent-run-prestart" ''
          #!${pkgs.bash}/bin/bash

          # Create data directory if it doesn't exist
          if ! test -d "$QBT_PROFILE"; then
            echo "Creating initial qBittorrent data directory in: $QBT_PROFILE"
            ${pkgs.coreutils}/bin/install -d -m 0755 -o "qbittorrent" -g "torrents" "$QBT_PROFILE"
          fi
        '';
      in "!${preStartScript}";

      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
      UMask = "0000";
    };

    environment = {
      QBT_PROFILE = "/var/lib/qbittorrent";
      QBT_WEBUI_PORT = "8082";
    };
  };

  users = {
    users."qbittorrent" = {
      group = "torrents";
      uid = 888;
    };
  };
}
