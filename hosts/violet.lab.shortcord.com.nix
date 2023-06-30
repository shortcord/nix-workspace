{ name, nodes, pkgs, lib, config, ... }:
let
  distributedUserSSHKeyPub = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnmaQeov9+Xv7z/ulQ0zPVDN3ZKW4AUK8IyoVkbUKQa"
  ];
in {
  age.secrets = {
    distributedUserSSHKey.file = ../secrets/general/distributedUserSSHKey.age;
    nix-serve.file = ../secrets/${name}/nix-serve.age;
    calckey-config.file = ../secrets/${name}/calckey-config.age;
  };

  system.stateVersion = "23.05";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/4b837b12-69c1-4e4e-8a97-9dd38fdba342";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2C1D-95D4";
      fsType = "vfat";
    };
  };

  systemd = {
    mounts = [
      {
        what = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
        where = "/btrfs";
        type = "btrfs";
        before = [ "systemd-tmpfiles-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        options = "noatime,degraded,compress=zstd,discard=async,space_cache=v2";
      }
      {
        what = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
        where = "/var/lib/docker";
        type = "btrfs";
        before = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
        options =
          "noatime,degraded,compress=zstd,discard=async,space_cache=v2,subvolid=257";
      }
    ];
    network = {
      enable = true;
      networks = {
        "10-wan" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:51";
          networkConfig = {
            DHCP = "ipv4";
            DNS = "9.9.9.9";
            IPv6AcceptRA = true;
          };
        };
        "20-lan" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:52";
          linkConfig.RequiredForOnline = "no";
          address = [ "10.18.0.1/24" ];
          networkConfig = {
            IPv6SendRA = true;
            DHCPPrefixDelegation = true;
            IPv6AcceptRA = false;
          };
          extraConfig = ''
            [DHCPPrefixDelegation]
            UplinkInterface=eno1
            SubnetId=0
            Announce=yes
          '';
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
      configurationLimit = 50;
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
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };

  networking = {
    hostId = "7f09cf4e";
    hostName = "violet";
    domain = "lab.shortcord.com";
    useDHCP = false;
    #nameservers = [ "9.9.9.9" "2620:fe::fe" ];
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
      trustedInterfaces = [ "eno1" "eno2" ];
    };
    # interfaces."eno2" = {
    #   useDHCP = false;
    #   ipv4.addresses = [{
    #     address = "10.18.0.1";
    #     prefixLength = 24;
    #   }];
    # };
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "eno1";
      internalInterfaces = [ "eno2" ];
    };
  };

  nix.distributedBuilds = lib.mkForce false;

  environment.systemPackages = with pkgs; [ vim wget curl btrfs-progs ];

  users.users.remotebuild = {
    isNormalUser = true;
    openssh = { authorizedKeys.keys = distributedUserSSHKeyPub; };
  };

  services = {
    dhcpd4 = {
      enable = true;
      authoritative = true;
      interfaces = [ "eno2" ];
      extraConfig = ''
        option subnet-mask 255.255.255.0;
        option broadcast-address 10.18.0.255;
        option routers 10.18.0.1;
        option domain-name-servers 9.9.9.9;
        option domain-name "lab.shortcord.com";
        subnet 10.18.0.0 netmask 255.255.255.0 {
          range 10.18.0.5 10.18.0.200;
        }
      '';
      machines = [{
        hostName = "lilac.lab.shortcord.com";
        ipAddress = "10.18.0.2";
        ethernetAddress = "14:18:77:5b:a9:87";
      }];
    };
    nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets.nix-serve.path;
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedProxySettings = true;
      virtualHosts = {
        "binarycache.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://${config.services.nix-serve.bindAddress}:${
                toString config.services.nix-serve.port
              }";
          };
        };
      };
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
    oci-containers = {
      backend = "docker";
      containers = {
        "gitlab-runner" = {
          autoStart = true;
          image = "docker.io/gitlab/gitlab-runner:latest";
          volumes = [
            "gitlab-runner-config:/etc/gitlab-runner"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
        };
        # "calckey_web" = {
        #   autoStart = true;
        #   image = "docker.io/thatonecalculator/calckey:latest";
        #   volumes = [
        #     "calckey-data:/calckey/files:rw"
        #     "${config.age.secrets.calckey-config.path}:/calckey/.config/default.yml:ro"
        #   ];
        #   environment = {
        #     NODE_ENV = "production";
        #   };
        #   ports = [
        #     "3000:3000"
        #   ];
        # };
        # "redis" = {
        #   autoStart = true;
        #   image = "docker.io/redis:7.0-alpine";
        #   volumes = [
        #     "redis-data:/data:rw"
        #   ];
        # };
        # "calckey-db" = {
        #   autoStart = true;
        #   image = "docker.io/postgres:12.2-alpine";
        #   volumes = [
        #     "calckey-db-data:/var/lib/postgresql/data"
        #   ];
        #   environment = {
        #     POSTGRES_PASSWORD = "example-calckey-pass";
        #     POSTGRES_USER = "example-calckey-user";
        #     POSTGRES_DB = "calckey";
        #   };
        # };
      };
    };
  };

  users.users.short = { extraGroups = [ "wheel" "docker" ]; };

  systemd = {
    timers = {
      "update-dyndns-ipv4" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "update-dyndns-ipv4.service";
        };
      };
      "update-dyndns-ipv6" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "update-dyndns-ipv6.service";
        };
      };
    };
    services = {
      "update-dyndns-ipv4" = {
        script = ''
          set -eu
          ${pkgs.curl}/bin/curl https://ShortCord:7m6GWrH8TtdVZLm@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv4.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
      "update-dyndns-ipv6" = {
        script = ''
          set -eu
          ${pkgs.curl}/bin/curl https://ShortCord:7m6GWrH8TtdVZLm@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv6.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
