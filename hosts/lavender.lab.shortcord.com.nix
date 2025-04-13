{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "24.11";

  imports = [ ./general/all.nix ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "xfs";
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
    "/var/lib/minio/data" = {
      device = "/dev/disk/by-label/DATA";
      fsType = "xfs";
      options = [ "noatime" "nodiratime" "rw" "defaults" ];
    };
  };

  systemd = {
    network = {
      enable = true;
      wait-online.anyInterface = true;
      networks = {
        "10-lan" = {
          matchConfig.MACAddress = "14:18:77:5b:a9:87";
          linkConfig = {
            RequiredForOnline = true;
          };
          networkConfig = {
            DHCP = "yes";
            DNS = "127.0.0.1";
          };
        };
      };
    };
  };

  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    growPartition = true;
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [ "kvm-intel" ];
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    initrd = {
      availableKernelModules = [
        "ehci_pci"
        "ahci"
        "megaraid_sas"
        "3w_sas"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = false;
      allowPing = true;
    };
  };

  security.acme = {
    # there has to be a better way :(
    certs = {
      "admin.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "storage.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
    };
  };

  age.secrets = {
    minioSecret.file = ../secrets/${name}/minioSecret.age;
  };

  services = {
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
    };
    minio = {
      enable = true;
      rootCredentialsFile = config.age.secrets.minioSecret.path;
      listenAddress = "127.0.0.1:9000";
      consoleAddress = "127.0.0.1:9001";
      region = "de-01";
    };
    nginx = {
      package = pkgs.nginxQuic;
      enable = true;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedBrotliSettings = true;
      eventsConfig = ''
        worker_connections 20000;
      '';
      virtualHosts = {
        "admin.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          extraConfig = ''
            ignore_invalid_headers off;
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_set_header X-NginX-Proxy true;
            chunked_transfer_encoding off;
          '';

          locations."/" = {
            proxyPass = "http://${config.services.minio.consoleAddress}";
            proxyWebsockets = true;
          };
        };
        "storage.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          extraConfig = ''
            ignore_invalid_headers off;
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_set_header X-NginX-Proxy true;
            chunked_transfer_encoding off;
          '';

          locations."/" = {
            proxyPass = "http://${config.services.minio.listenAddress}";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_connect_timeout 600;
              chunked_transfer_encoding off;
            '';
          };
        };
      };
    };
  };
}
