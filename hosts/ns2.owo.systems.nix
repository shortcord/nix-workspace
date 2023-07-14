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
      enable = true;
      allowedUDPPorts = [ 53 51820 ];
      allowedTCPPorts = [ 53 22 80 443 ];
      allowPing = true;
    };
    wireguard = {
      enable = true;
      interfaces.wg0 = {
        ips = [ "10.6.210.27/32" ];
        listenPort = 51820;
        privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
        postSetup = ''
          printf "nameserver 10.6.210.1" | ${pkgs.openresolv}/bin/resolvconf -a wg0 -m 0'';
        postShutdown = "${pkgs.openresolv}/bin/resolvconf -d wg0";
        peers = [{
          publicKey = "ePYkBTYZaul66VdGLG70IZcCvIaZ7aSeRrkb+hskhiQ=";
          presharedKeyFile = config.age.secrets.wireguardPresharedKey.path;
          endpoint = "147.135.125.64:51820";
          persistentKeepalive = 15;
          allowedIPs = [
            "10.6.210.1/32"
            "10.0.0.0/24" # Access to pdns API + Master MySQL node (dhcp)
            "10.50.0.20/32" # Allow access to ns1 for lego ACME
          ];
        }];
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
        role = "slave";
        serverId = 2;
        masterUser = "replication_user";
        masterPassword = "T9ogXl64hI4BRg5u5PA+S0lym6jwOnZu";
        masterHost = "sql01.rack";
      };
    };
    powerdns = {
      enable = true;
      extraConfig = ''
        expand-alias=yes

        webserver=yes
        webserver-address=127.0.0.1
        webserver-port=8081
        webserver-allow-from=0.0.0.0/0,::/0
        api=no

        launch=gmysql

        gmysql-port=3306
        gmysql-host=127.0.0.1
        gmysql-dbname=powerdns
        gmysql-user=powerdns
        gmysql-password=password
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
      };
    };
  };
}
