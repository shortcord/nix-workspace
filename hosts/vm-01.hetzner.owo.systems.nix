let
  disks = {
    root = "/dev/disk/by-uuid/79bdfbec-983a-41ac-9603-a207beae1f19";
    boot = "/dev/disk/by-uuid/DD73-4F08";
  };
in { name, nodes, pkgs, lib, config, modulesPath, ... }: {

  age.secrets = {
    prometheusBasicAuthPassword.file =
      ../secrets/${name}/prometheusBasicAuthPassword.age;
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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.sudo.wheelNeedsPassword = false;

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
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
    };
  };

  environment.systemPackages = with pkgs; [ vim git ];

  services = {
    fail2ban = { enable = true; };
    openssh = { enable = true; };
    nginx = {
      package = pkgs.nginxQuic;
      enable = true;
      virtualHosts = {
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
        "grafana.vm-01.hetzner.owo.systems" = {
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
      };
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
      };
      globalConfig = {
        evaluation_interval = "1m";
        scrape_interval = "5s";
      };
      scrapeConfigs = [
        # {
        #   job_name = "blackbox-exporters";
        #   metrics_path = "/probe";
        #   params = { module = [ "icmp" ]; };
        #   static_configs = [{
        #     targets = [
        #       "home.shortcord.com"
        #       "router.cloud.shortcord.com"
        #       "violet.home.shortcord.com"
        #     ];
        #   }];
        #   relabel_configs = [
        #     {
        #       source_labels = [ "__address__" ];
        #       target_label = "__param_target";
        #     }
        #     {
        #       source_labels = [ "__param_target" ];
        #       target_label = "instance";
        #     }
        #     {
        #       target_label = "__address__";
        #       replacement = "127.0.0.1:9115";
        #     }
        #   ];
        # }
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
          basic_auth = {
            username = "app";
            password_file = config.age.secrets.prometheusBasicAuthPassword.path;
          };
          metrics_path = "/pdns/metrics";
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
          domain = "grafana.vm-01.hetzner.owo.systems";
          root_url = "https://grafana.vm-01.hetzner.owo.systems";
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
    # oci-containers = {
    #   backend = "docker";
    #   containers. = {
    #     "moustail.dev" = {

    #     };
    #   };
    # };
  };

  users.users.short = { extraGroups = [ "wheel" "docker" ]; };
}
