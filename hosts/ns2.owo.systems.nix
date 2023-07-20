{ name, nodes, pkgs, lib, config, ... }: {
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
  };

  swapDevices = [{ device = "/.swapfile"; }];
  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = false;

  system.stateVersion = "22.11";

  boot = {
    growPartition = true;
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [ "ata-piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };
    initrd = {
      availableKernelModules =
        [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
      kernelModules = [ ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  age.secrets = {
    wireguardPrivateKey.file = ../secrets/${name}/wireguardPrivateKey.age;
    wireguardPresharedKey.file = ../secrets/${name}/wireguardPresharedKey.age;
    powerdnsConfig.file = ../secrets/${name}/powerdnsConfig.age;
  };

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
    hostName = "ns2";
    domain = "owo.systems";
    useDHCP = true;
    nameservers = [ "9.9.9.9" "2620:fe::fe" ];
    defaultGateway = {
      address = "66.135.8.1";
      interface = "ens3";
    };
    interfaces.ens3 = {
      ipv4.addresses = [{
        address = "66.135.9.121";
        prefixLength = 32;
      }];
    };
    firewall = {
      enable = false;
      allowedUDPPorts = [ 53 51820 51821 ];
      allowedTCPPorts = [ 53 22 80 443 ];
      allowPing = true;
    };
    wireguard = {
      enable = true;
      interfaces = {
        wg1 = {
          ips = [ "10.7.210.1/32" ];
          listenPort = 51821;
          privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
          peers = [{
            publicKey = "x8o7GM5Fk1EYZK9Mgx4/DIt7DxAygvKg310G6+VHhUs=";
            persistentKeepalive = 15;
            allowedIPs = [ "10.7.210.2/32" ];
          }];
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ vim wget curl ];

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
    };
    fail2ban = { enable = true; };
    mysql = {
      package = pkgs.mariadb;
      enable = true;
      replication = {
        role = "master";
        serverId = 2;
        ## This information is only here to prevent the init script
        # from erroring out during deployment 
        masterUser = "replication_user";
        masterPassword = "temppassword";
        slaveHost = "10.7.210.2";
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
        webserver-allow-from=127.0.0.1,::1
        api=yes
        api-key=$API_KEY

        launch=gmysql

        gmysql-port=3306
        gmysql-host=$SQL_HOST
        gmysql-dbname=$SQL_DATABASE
        gmysql-user=$SQL_USER
        gmysql-password=$SQL_PASSWORD
        gmysql-dnssec=yes
      '';
    };
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = false;
          port = 9100;
          listenAddress = "127.0.0.1";
        };
      };
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "ns2.owo.systems" = {
          enableACME = false;
          forceSSL = false;
          locations = {
            "/" = { return = "302 https://shortcord.com"; };
            # "/pdns/" = { proxyPass = "http://127.0.0.1:8081$request_uri"; };
            # "/node-exporter/" = {
            #   proxyPass = "http://${
            #       toString
            #       config.services.prometheus.exporters.node.listenAddress
            #     }:${
            #       toString config.services.prometheus.exporters.node.port
            #     }$request_uri";
            # };
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
      };
    };
  };
}
