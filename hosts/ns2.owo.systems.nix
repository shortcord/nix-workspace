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

  systemd = {
    network = {
      enable = true;
      networks = {
        "10-wan" = {
          matchConfig.MACAddress = "56:00:04:63:08:52";
          networkConfig = {
            DHCP = "no";
            DNS = [ "9.9.9.9" "2620:fe::fe" ];
            Address = [
              "66.135.9.121/23"
              "2001:19f0:1000:1512:5400:04ff:fe63:0852/64"
            ];
            Gateway = "66.135.8.1";
            IPv6AcceptRA = true;
          };
        };
      };
    };
  };

  networking = {
    hostName = "ns2";
    domain = "owo.systems";
    useDHCP = false;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 51820 ];
      allowedTCPPorts = [ 53 22 80 443 ];
      allowPing = true;
    };
    wireguard = {
      enable = true;
      interfaces = {
        wg1 = {
          ips = [ "10.7.210.1/32" ];
          listenPort = 51820;
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
    resolved.enable = false;
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

        local-address=66.135.9.121:53, [2001:19f0:1000:1512:5400:04ff:fe63:0852]:53

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
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
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
        "${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { return = "302 https://shortcord.com"; }; };
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
