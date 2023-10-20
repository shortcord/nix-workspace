{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "22.11";

  age.secrets = {
    prometheusBasicAuthPassword.file =
      ../secrets/${name}/prometheusBasicAuthPassword.age;
    minioPrometheusBearerToken = {
      owner = "prometheus";
      group = "prometheus";
      file = ../secrets/${name}/minioPrometheusBearerToken.age;
    };
    wireguardPrivateKey.file = ../secrets/${name}/wireguardPrivateKey.age;
    powerdnsConfig.file = ../secrets/${name}/powerdnsConfig.age;
    powerdns-env.file = ../secrets/${name}/powerdns-env.age;
  };

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./${name}/hardware.nix
    ./${name}/nginx.nix
    ./${name}/xmpp.nix
    ./${name}/prometheus.nix
    ./${name}/pterodactyl.nix
    ./${name}/xmpp.nix
    ./${name}/writefreely.nix
    ./${name}/powerdns.nix
    ./${name}/uptime-kuma.nix
    ./general/promtail.nix
  ];

  nix = {
    buildMachines = [{
      hostName = "violet.lab.shortcord.com";
      systems = [ "x86_64-linux" "i686-linux" ];
      protocol = "ssh-ng";
      maxJobs = 20;
      sshUser = "remotebuild";
      sshKey = config.age.secrets.distributedUserSSHKey.path;
    }];
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  systemd.network = {
    enable = true;
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
        routes = [{
          routeConfig = {
            Scope = "link";
            Destination = "172.31.1.1";
          };
        }];
      };
    };
  };

  networking = {
    hostName = "vm-01";
    domain = "hetzner.owo.systems";
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 51820 53 ];
      allowedTCPPorts = [
        # OpenSSH
        22
        # PowerDNS
        53
        # Nginx w/HTTPS
        80
        443
      ];
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
            endpoint = builtins.concatStringsSep ":" [
              nodes."ns2.owo.systems".config.networking.fqdn
              (toString
                nodes."ns2.owo.systems".config.networking.wireguard.interfaces.wg1.listenPort)
            ];
          }];
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ vim git ];

  containers = {
    testing = {
      autoStart = true;
      privateNetwork = true;
      hostAddress6 = "fc00::1";
      localAddress6 = "2a01:4f8:c012:a734::10";
      config = { config, pkgs, ... }: {
        services.httpd.enable = true;
        networking.firewall = {
          allowedTCPPorts = [ 22 80 ];
          allowPing = true;
        };
      };
    };
  };

  services = {
    ndppd = {
      enable = false;
      proxies = {
        "ens3" = {
          rules = { "2a01:4f8:c012:a734::/64" = { method = "static"; }; };
        };
      };
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
    oci-containers = {
      backend = "docker";
      containers = {
        "shortcord.com" = {
          autoStart = true;
          image =
            "gitlab.shortcord.com:5050/shortcord/shortcord.com:ad3e6c0218ebcda9247b575d7f3b65bbea9a3e49";
          ports = [ "127.0.0.2:81:80" ];
        };
        "owo.solutions" = {
          autoStart = true;
          image =
            "gitlab.shortcord.com:5050/owo.solutions/homepage:21d37ec71927af3ca6f0fce52e702e323a468fcb";
          ports = [ "127.0.0.2:82:80" ];
        };
      };
    };
  };

  users.users.short = { extraGroups = [ "wheel" "docker" ]; };
}
