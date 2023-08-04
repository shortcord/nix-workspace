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

  networking = {
    useDHCP = false;
    hostName = "vm-01";
    domain = "hetzner.owo.systems";
    nameservers = [ "127.0.0.1" "::1" ];
    defaultGateway = {
      address = "172.31.1.1";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
    };
    interfaces.ens3 = {
      ipv4.addresses = [{
        address = "88.198.125.192";
        prefixLength = 32;
      }];
      ipv6.addresses = [{
        address = "2a01:4f8:c012:a734::1";
        prefixLength = 64;
      }];
    };
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
        # Prosody XMPP
        5000
        5222
        5269
        5281
        5347
        5582
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
            endpoint = "${nodes."ns2.owo.systems".config.networking.fqdn}:${
                toString
                nodes."ns2.owo.systems".config.networking.wireguard.interfaces.wg1.listenPort
              }";
          }];
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ vim git ];

  services = {
    ndppd = {
      enable = true;
      proxies.ens3 = {
        rules."primary" = {
          network = "2a01:4f8:c012:a734::/64";
          method = "static";
        };
      };
    };
    fail2ban = { enable = true; };
    openssh = { enable = true; };
    writefreely = {
      enable = true;
      host = "blog.mousetail.dev";
      acme.enable = true;
      nginx = {
        enable = true;
        forceSSL = true;
      };
      database = {
        type = "sqlite3";
        name = "writefreely";
      };
      admin.name = "short";
      settings.app.single_user = true;
    };
    grafana = {
      enable = true;
      settings = {
        analytics = { reporting_enabled = false; };
        users = { allow_sign_up = false; };
        "auth.anonymous" = {
          enabled = true;
          org_name = "Main Org.";
          org_role = "Viewer";
          hide_version = true;
        };
        smtp = {
          enabled = true;
          host = "10.7.210.1:25";
          from_name = "${config.networking.fqdn}";
          from_address = "grafana-noreply@${config.networking.fqdn}";
        };
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "grafana.${config.networking.fqdn}";
          root_url = "https://grafana.${config.networking.fqdn}";
        };
      };
    };
    powerdns = {
      enable = true;
      secretFile = config.age.secrets.powerdnsConfig.path;
      extraConfig = ''
        resolver=[::1]:53
        expand-alias=yes

        local-address=88.198.125.192:53, [2a01:4f8:c012:a734::1]:53

        webserver=yes
        webserver-address=127.0.0.1
        webserver-port=8081
        webserver-allow-from=0.0.0.0/0,::/0
        api=yes
        api-key=$API_KEY

        launch=gmysql

        gmysql-port=3306
        gmysql-host=127.0.0.1
        gmysql-dbname=$SQL_DATABASE
        gmysql-user=$SQL_USER
        gmysql-password=$SQL_PASSWORD
        gmysql-dnssec=yes
      '';
    };
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
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
        "powerdns-admin" = {
          autoStart = true;
          image = "powerdnsadmin/pda-legacy:v0.4.1";
          volumes = [ "powerdns-admin-data:/data" ];
          environmentFiles = [ config.age.secrets.powerdns-env.path ];
          ports = [ "127.0.0.1:9191:80" ];
        };
        "shortcord.com" = {
          autoStart = true;
          image =
            "gitlab.shortcord.com:5050/shortcord/shortcord.com:ad3e6c0218ebcda9247b575d7f3b65bbea9a3e49";
          ports = [ "127.0.0.1:9200:80" ];
        };
      };
    };
  };

  users.users.short = { extraGroups = [ "wheel" "docker" ]; };
}
