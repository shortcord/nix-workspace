{ name, nodes, pkgs, nixpkgs-unstable, lib, config, modulesPath, ... }: {
  system.stateVersion = "22.11";

  age.secrets = {
    wireguardPrivateKey.file = ../secrets/${name}/wireguardPrivateKey.age;
  };

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./${name}/hardware.nix
    ./${name}/nginx.nix
    ./${name}/websites.nix
    ./${name}/prometheus.nix
    ./${name}/powerdns.nix
    ./${name}/uptime-kuma.nix
    ./${name}/influxdb.nix
    ./${name}/ai.nix
    # ./${name}/wings.nix # Removed until I update the flake to 25.05
    ./general/all.nix
  ];

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "20-wan" = {
        matchConfig = {
          Name = "ens3";
          MACAddress = "96:00:02:16:8c:20";
        };
        networkConfig = {
          DHCP = "no";
          DNS = [ "127.0.0.1" ];
          Address = [ "88.198.125.192/32" "2a01:4f8:c012:a734::1/64" ];
          Gateway = [ "172.31.1.1" "fe80::1" ];
          IPv6AcceptRA = true;
          IPv6ProxyNDP = true;
          IPv6ProxyNDPAddress = builtins.map (ct: ct.localAddress6)
            (builtins.attrValues config.containers);
        };
        routes = [
          {
            Scope = "link";
            Destination = "172.31.1.1";
          }
        ];
      };
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 51820 ];
      allowedTCPPorts = [ 22 ];
      allowPing = true;
      trustedInterfaces = [
        "wg0"
        config.services.tailscale.interfaceName
        "docker0"
      ];
      hosts = {
        "100.64.0.9" = [ "search.owo.solutions" ];
      };
    };
    wireguard = {
      enable = true;
      interfaces = {
        wg0 = {
          ips = [ "10.7.210.2/32" ];
          listenPort = 51820;
          privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
          peers = [{
            publicKey = "2a8w4y36L4hiG2ijQKZOfKTar28A4SPtupZnTXVUrTI=";
            persistentKeepalive = 15;
            allowedIPs = [ "10.7.210.1/32" ];
            endpoint = "66.135.9.121:51820";
          }];
        };
      };
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "netbox-3.7.8" "nextcloud-27.1.11" ];
  };

  services = {
    nginx = {
      virtualHosts = {
        "vreygal.com" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/".return = "302 https://mastodon.art/@VReygal";
        };
      };
    };
    mysql = {
      package = pkgs.mariadb;
      enable = true;
      settings = let cfg = config.services.mysql;
      in {
        mysqld = {
          server_id = 3;
          bind_address = "0.0.0.0";
          log_bin = true;
          log_basename = "mysql_1";
          binlog_format = "mixed";
          skip_name_resolve = true;
          max_connect_errors = 4294967295;
          proxy_protocol_networks = "172.18.0.0/16,100.64.0.0/16";
          gtid_strict_mode = true;
        };
      };
    };
  };
  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
      };
    };
    oci-containers = {
      backend = "docker";
      containers = {
        "maxscale" = {
          autoStart = true;
          image = "docker.io/mariadb/maxscale:latest";
          volumes = [ "maxscale-config:/var/lib/maxscale/:rw" ];
          ports = [ "3366:3366" ];
        };
      };
    };
  };

  users.users = {
    short = { extraGroups = [ "wheel" "docker" ]; };
    theresnotime = {
      isNormalUser = true;
      openssh = {
        authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEFHoL3e9jjUsOuqeFfyYIwPTrb/iVyJiOtDT3V4vHG6" ];
      };
    };
  };
}
