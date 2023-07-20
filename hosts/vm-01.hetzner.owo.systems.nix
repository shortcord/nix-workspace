let
  disks = {
    root = "/dev/disk/by-uuid/79bdfbec-983a-41ac-9603-a207beae1f19";
    boot = "/dev/disk/by-uuid/DD73-4F08";
  };
in { name, nodes, pkgs, lib, config, modulesPath, ... }: {

  age.secrets = {
    prometheusBasicAuthPassword.file =
      ../secrets/${name}/prometheusBasicAuthPassword.age;
    wireguardPrivateKey.file = ../secrets/${name}/wireguardPrivateKey.age;
    powerdnsConfig.file = ../secrets/${name}/powerdnsConfig.age;
    powerdns-env.file = ../secrets/${name}/powerdns-env.age;
  };

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd = {
      availableKernelModules =
        [ "ata_piix" "virtio_pci" "virtio_scsi" "xhci_pci" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = disks.root;
      fsType = "ext4";
    };
    "/boot" = {
      device = disks.boot;
      fsType = "vfat";
    };
  };

  boot = {
    loader = {
      grub = {
        enable = true;
        version = 2;
        device = "/dev/sda";
      };
    };
  };

  swapDevices = [ ];
  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = false;
  hardware.cpu.intel.updateMicrocode = false;

  system.stateVersion = "22.11";

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

  security.acme = {
    certs = {
      "xmpp.${config.networking.fqdn}" = {
        reloadServices = [ "prosody.service" ];
        postRun = ''
          cp fullchain.pem "${
            config.users.users."${config.services.prosody.user}".home
          }/"
          cp key.pem "${
            config.users.users."${config.services.prosody.user}".home
          }/"
          chown ${config.services.prosody.user}:${config.services.prosody.group} "${
            config.users.users."${config.services.prosody.user}".home
          }/fullchain.pem"
          chown ${config.services.prosody.user}:${config.services.prosody.group} "${
            config.users.users."${config.services.prosody.user}".home
          }/key.pem"
        '';
        extraDomainNames = [
          "upload.xmpp.${config.networking.fqdn}"
          "conference.xmpp.${config.networking.fqdn}"
        ];
      };
    };
  };

  networking = {
    useDHCP = false;
    hostName = "vm-01";
    domain = "hetzner.owo.systems";
    nameservers = [ "9.9.9.9" "2620:fe::fe" ];
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
      interfaces.wg0 = {
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

  environment.systemPackages = with pkgs; [ vim git ];

  services = {
    fail2ban = { enable = true; };
    openssh = { enable = true; };
    nginx = {
      package = pkgs.nginxQuic;
      enable = true;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedBrotliSettings = true;
      virtualHosts = {
        "miauws.life" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          serverAliases = [ "miauws.tech" ];
          locations."/" = { return = "302 https://mousetail.dev"; };
        };
        "netbox.owo.solutions" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8080"; };
          extraConfig = ''
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        "ip.mousetail.dev" = {
          serverAliases = [ "ipv4.mousetail.dev" "ipv6.mousetail.dev" ];
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { return = "200 $remote_addr"; };
          extraConfig = ''
            add_header Content-Type text/plain;
          '';
        };
        "freekobolds.com" = {
          serverAliases = [ "www.freekobolds.com" ];
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            return = "302 https://www.twitch.tv/touchscalytail";
          };
        };
        "shinx.dev" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { return = "302 https://francessco.us"; };
        };
        "owo.gallery" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { return = "302 https://mousetail.dev"; };
        };
        "pawtism.dog" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { return = "302 https://estrogen.dog"; };
        };
        "grafana.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${
                toString config.services.grafana.settings.server.http_addr
              }:${toString config.services.grafana.settings.server.http_port}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
        "powerdns.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8081"; };
        };
        "powerdns-admin.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:9191"; };
        };
        "xmpp.${config.networking.fqdn}" = {
          serverAliases = [
            "upload.xmpp.${config.networking.fqdn}"
            "conference.xmpp.${config.networking.fqdn}"
          ];
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { return = "302 https://mousetail.dev"; };
        };
      };
    };
    prosody = {
      enable = true;
      admins = [ "short@xmpp.${config.networking.fqdn}" ];
      ssl = {
        cert = "${
            config.users.users."${config.services.prosody.user}".home
          }/fullchain.pem";
        key = "${
            config.users.users."${config.services.prosody.user}".home
          }/key.pem";
      };
      virtualHosts = {
        "xmpp.${config.networking.fqdn}" = {
          enabled = true;
          domain = "xmpp.${config.networking.fqdn}";
          ssl = {
            cert = "${
                config.users.users."${config.services.prosody.user}".home
              }/fullchain.pem";
            key = "${
                config.users.users."${config.services.prosody.user}".home
              }/key.pem";
          };
        };
      };
      muc = [{ domain = "conference.xmpp.${config.networking.fqdn}"; }];
      uploadHttp = { domain = "upload.xmpp.${config.networking.fqdn}"; };
    };
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
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = true;
        };
        blackbox = {
          enable = true;
          openFirewall = false;
          configFile = pkgs.writeText "blackbox-config" ''
            modules:
              http_2xx:
                prober: http
                timeout: 5s
                http:
                  valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
                  valid_status_codes: [ 200 ]
                  method: GET
                  follow_redirects: true
                  fail_if_ssl: false
                  fail_if_not_ssl: true
                  preferred_ip_protocol: "ip6"
                  ip_protocol_fallback: true
              icmp_probe:
                prober: icmp
                timeout: 5s
                icmp:
                  preferred_ip_protocol: "ip6"
          '';
        };
      };
      globalConfig = {
        evaluation_interval = "1m";
        scrape_interval = "5s";
      };
      scrapeConfigs = [
        {
          job_name = "blackbox-exporters";
          metrics_path = "/probe";
          params = { module = [ "icmp_probe" ]; };
          static_configs = [{
            targets = [
              "home.shortcord.com"
              "router.cloud.shortcord.com"
              "maus.home.shortcord.com"
              "violet.lab.shortcord.com"
              "lilac.lab.shortcord.com"
            ];
          }];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:9115";
            }
          ];
        }
        {
          job_name = "node-exporters";
          dns_sd_configs = [{
            names = [ "_node-exporter.prometheus.owo.systems" ];
            type = "SRV";
            refresh_interval = "5s";
          }];
        }
        {
          job_name = "node-exporters-https";
          basic_auth = {
            username = "app";
            password_file = config.age.secrets.prometheusBasicAuthPassword.path;
          };
          metrics_path = "/node-exporter/metrics";
          dns_sd_configs = [{
            names = [ "_node-exporter-https.prometheus.owo.systems" ];
            type = "SRV";
            refresh_interval = "5s";
          }];
        }
        {
          job_name = "powerdns-exporter";
          metrics_path = "/metrics";
          dns_sd_configs = [{
            names = [ "_powerdns-exporter.owo.systems" ];
            type = "SRV";
            refresh_interval = "5s";
          }];
        }
      ];
    };
    grafana = {
      enable = true;
      settings = {
        analytics = { reporting_enabled = false; };
        users = { allow_sign_up = false; };
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
          image = "powerdnsadmin/pda-legacy:v0.4.1";
          volumes = [ "powerdns-admin-data:/data" ];
          environmentFiles = [ config.age.secrets.powerdns-env.path ];
          ports = [ "127.0.0.1:9191:80" ];
        };
      };
    };
  };

  users.users.short = { extraGroups = [ "wheel" "docker" ]; };
}
