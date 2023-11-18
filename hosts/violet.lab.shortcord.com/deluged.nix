{ name, pkgs, config, lib, ... }: {
  # age.secrets.deluged = {
  #   file = ../../secrets/${name}/deluged.age;
  #   owner = config.services.deluge.user;
  #   group = config.services.deluge.group;
  # };
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
      enable = false;
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
        listen_interface = "tun0";
        outgoing_interface = "tun0";
      };
    };
    nginx = {
      virtualHosts = {
        # "deluged.${config.networking.fqdn}" = {
        #   kTLS = true;
        #   http2 = true;
        #   http3 = true;
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = { proxyPass = "http://127.0.0.1:8112"; };
        # };
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
  systemd.services.deluged = {
    serviceConfig = { UMask = lib.mkForce "0002"; };
  };

  systemd.services.qbittorrent = {
    # based on the plex.nix service module and
    # https://github.com/qbittorrent/qBittorrent/blob/master/dist/unix/systemd/qbittorrent-nox%40.service.in
    description = "qBittorrent-nox service";
    documentation = [ "man:qbittorrent-nox(1)" ];
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "qbittorrent";
      Group = "qbittorrent";

      # Run the pre-start script with full permissions (the "!" prefix) so it
      # can create the data directory if necessary.
      ExecStartPre = let
        preStartScript = pkgs.writeScript "qbittorrent-run-prestart" ''
          #!${pkgs.bash}/bin/bash

          # Create data directory if it doesn't exist
          if ! test -d "$QBT_PROFILE"; then
            echo "Creating initial qBittorrent data directory in: $QBT_PROFILE"
            install -d -m 0755 -o "qbittorrent" -g "qbittorrent" "$QBT_PROFILE"
          fi
        '';
      in "!${preStartScript}";

      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
      UMask = "0002";
    };

    environment = {
      QBT_PROFILE = "/var/lib/qbittorrent";
      QBT_WEBUI_PORT = "8082";
    };
  };

  users = {
    groups."qbittorrent" = { gid = 888; };
    users."qbittorrent" = {
      group = "qbittorrent";
      uid = 888;
    };
  };
}
