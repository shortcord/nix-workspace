{ name, nodes, pkgs, nixpkgs-unstable, lib, config, modulesPath, ... }: {
  system.stateVersion = "22.11";

  age.secrets = {
    wireguardPrivateKey.file = ../secrets/${name}/wireguardPrivateKey.age;
    wingsToken = {
      file = ../secrets/${name}/wingsToken.age;
      owner = config.services.pterodactyl.wings.user;
      group = config.services.pterodactyl.wings.group;
    };
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
    ./${name}/xmpp.nix
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

  environment.systemPackages = with pkgs; [ vim git ];
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "netbox-3.7.8" "nextcloud-27.1.11" ];
  };

  services = {
    nginx = {
      virtualHosts = {
        "wings.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://127.0.0.1:4443";
            extraConfig = ''
              client_max_body_size 0;
            '';
          };
        };
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
    pterodactyl.wings = {
      enable = true;
      package = pkgs.pterodactyl-wings;
      openFirewall = true;
      allocatedTCPPorts = [ 6000 6001 6002 6003 6004 6005 ];
      allocatedUDPPorts = [ 6000 6001 6002 6003 6004 6005 ];
      settings = {
        system.user.rootless = {
          enabled = true;
          container_uid = config.users.users."pterodactyl".uid;
          container_gid = config.users.groups."pterodactyl".gid;
        };
        api = {
          host = "127.0.0.1";
          port = 4443;
        };
        remote = "https://panel.owo.solutions";
      };
      extraConfigFile = config.age.secrets.wingsToken.path;
    };
    mysql = {
      package = pkgs.mariadb;
      enable = true;
      replication = {
        role = "slave";
        serverId = 3;
        ## This information is only here to prevent the init script
        # from erroring out during deployment 
        masterHost = "10.7.210.1";
        masterUser = "replication_user";
        masterPassword = "temppassword";
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
    oci-containers.backend = "docker";
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
