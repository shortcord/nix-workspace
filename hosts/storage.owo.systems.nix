{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "22.11";

  boot.loader.grub = {
    device = "/dev/disk/by-id/ata-HGST_HUS726060ALE610_K8GEVAAD";
    enable = true;
  };

  boot.initrd = {
    availableKernelModules =
      [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
    kernelModules = [ "nvme" ];
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/5A9E-428F";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-uuid/9b19cf19-42f6-46a9-ae4d-c68a084c2c8d";
      fsType = "ext4";
    };
    "/mnt/disk1" = {
      device = "/dev/disk/by-uuid/4c30c325-b614-493b-b4a7-53eb977b9d70";
      fsType = "xfs";
      options = [ "defaults" "noatime" ];
    };
    "/mnt/disk2" = {
      device = "/dev/disk/by-uuid/5f800b1c-9acd-470c-b707-1062f647c0fe";
      fsType = "xfs";
      options = [ "defaults" "noatime" ];
    };
    "/mnt/disk3" = {
      device = "/dev/disk/by-uuid/586bf7be-ca72-4795-8a7d-6b8f75797b66";
      fsType = "xfs";
      options = [ "defaults" "noatime" ];
    };
    "/mnt/disk4" = {
      device = "/dev/disk/by-uuid/4c50bd52-137f-46ce-a7df-db8c706206d9";
      fsType = "xfs";
      options = [ "defaults" "noatime" ];
    };
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  imports = [ ./general/all.nix ];

  age.secrets = {
    minioSecret.file = ../secrets/${name}/minioSecret.age;
  };

  networking = {
    useDHCP = false;
    nameservers = [ "127.0.0.1" "::1" ];
    defaultGateway = {
      address = "5.9.99.97";
      interface = "enp3s0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp3s0";
    };
    interfaces.enp3s0 = {
      ipv4.addresses = [{
        address = "5.9.99.123";
        prefixLength = 27;
      }];
      ipv6.addresses = [{
        address = "2a01:4f8:162:314e::1";
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

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "short@shortcord.com";
      dnsProvider = "pdns";
      credentialsFile = config.age.secrets.acmeCredentialsFile.path;
      reloadServices = [ "minio.service" ];
    };
    certs = {
      "storage.owo.systems" = {
        dnsProvider = "pdns";
        webroot = null;
      };
    };
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
    fail2ban = { enable = true; };
    openssh = { enable = true; };
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = true;
          port = 9100;
        };
      };
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
        "storage.owo.systems" = {
          serverAliases = [ "*.storage.owo.systems" ];
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
        "s3.boldrx.com" = {
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
          };
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ xfsprogs ];

  security.sudo.wheelNeedsPassword = false;
}
