{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "22.11";

  boot.loader.grub = {
    device = "/dev/sda";
    version = 2;
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

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  age.secrets = {
    minioSecret.file = ../secrets/${name}/minioSecret.age;
    acmeCredentialsFile.file = ../secrets/${name}/acmeCredentialsFile.age;
  };

  networking = {
    useDHCP = false;
    hostName = "storage";
    domain = "owo.systems";
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
      allowedUDPPorts = [ 51820 ];
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
          '';

          locations."/" = {
            proxyPass = "http://${config.services.minio.consoleAddress}";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-NginX-Proxy true;
              real_ip_header X-Real-IP;

              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              chunked_transfer_encoding off;
            '';
          };
        };
        "storage.${config.networking.fqdn}" = {
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
          '';

          locations."/" = {
            proxyPass = "http://${config.services.minio.listenAddress}";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              proxy_http_version 1.1;
              proxy_set_header Connection "";
              chunked_transfer_encoding off;
            '';
          };
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ xfsprogs ];

  security.sudo.wheelNeedsPassword = false;
}
