{ name, nodes, pkgs, lib, config, ... }:
let
  distributedUserSSHKeyPub = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnmaQeov9+Xv7z/ulQ0zPVDN3ZKW4AUK8IyoVkbUKQa"
  ];
in {
  age.secrets = {
    distributedUserSSHKey.file = ../secrets/general/distributedUserSSHKey.age;
    wingsToken = {
      file = ../secrets/${name}/wingsToken.age;
      owner = config.services.pterodactyl.wings.user;
      group = config.services.pterodactyl.wings.group;
    };
  };

  system.stateVersion = "23.05";

  imports = [
    ./general/all.nix
    ./general/dyndns-ipv4.nix
    ./general/dyndns-ipv6.nix
    ./${name}/hydra.nix
    # ./${name}/ipfs.nix
    # ./${name}/minio.nix
    ./${name}/nginx.nix
    ./${name}/jellyfin.nix
    ./${name}/gallery-dl-sync.nix
    ./${name}/repo-sync.nix
    ./${name}/komga.nix
    ./${name}/torrenting.nix
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/4b837b12-69c1-4e4e-8a97-9dd38fdba342";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2C1D-95D4";
      fsType = "vfat";
    };
    "/btrfs" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
      ];
    };
    "/var/lib/docker" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=257"
      ];
    };
    "/var/lib/libvirt/images/pool" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=741"
      ];
    };
    # "/nix" = {
    #   device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
    #   fsType = "btrfs";
    #   options = [ "noatime" "degraded" "compress=zstd" "discard=async" "space_cache=v2" "subvolid=598" ];
    # };
  };

  systemd = {
    network = {
      enable = true;
      netdevs = {
        vmbr0 = {
          netdevConfig = {
            Kind = "bridge";
            Name = "vmbr0";
          };
        };
      };
      networks = {
        "10-wan" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:51";
          networkConfig = {
            DHCP = "ipv4";
            DNS = "127.0.0.1";
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
            DHCPServer = true;
          };
          dhcpPrefixDelegationConfig = {
            UplinkInterface = "eno1";
            SubnetId = 0;
            Announce = true;
          };
          dhcpServerConfig = {
            ServerAddress= "10.18.0.1/24";
            DNS = "10.18.0.1";
            EmitDNS = true;
          };
          ipv6SendRAConfig = {
            DNS = "_link_local";
            EmitDNS = true;
          };
        };
        # "30-home" = {
        #   matchConfig.MACAddress = "C8:1F:66:E6:7A:54";
        #   linkConfig.RequiredForOnline = "no";
        #   address = [ "192.168.15.2/24" ];
        #   networkConfig = {
        #     DHCP = "no";
        #     DNS = "no";
        #     IPv6AcceptRA = false;
        #   };
        # };
        "40-lan2" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:53";
          linkConfig.RequiredForOnline = "no";
          address = [ "192.168.15.1/24" ];
          networkConfig = {
            DHCP = "no";
            DNS = "no";
            IPv6AcceptRA = false;
          };
        };
        "vmbr0" = {
          matchConfig.Name = "vmbr0";
          linkConfig.RequiredForOnline = "no";
          networkConfig = {
            DHCP = "no";
            DNS = "no";
            Address = [ "fd6f:357c:c101::1/48" ];
            IPv6AcceptRA = false;
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
    kernelModules = [ "jool" ];
    extraModulePackages = [ pkgs.linuxKernel.packages.linux_6_1.jool ];
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
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 5201 ];
      allowedTCPPorts = [ 22 80 443 5201 ];
      allowPing = true;
      trustedInterfaces = [ "eno1" "eno2" "eno3" "eno4" "vmbr0" ];
    };
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "eno1";
      internalInterfaces = [ "eno2" "eno3" ];
    };
    jool = {
      enable = true;
      nat64 = {
        "default" = {
          framework = "netfilter";
          global.pool6 = "64:ff9b::/96";
        };
      };
    };
  };

  nix = {
    buildMachines = [
      {
        hostName = "localhost";
        systems = [ "x86_64-linux" "i686-linux" ];
        supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        maxJobs = 8;
      }
      {
        hostName = "lilac.lab.shortcord.com";
        systems = [ "x86_64-linux" "i686-linux" ];
        supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        protocol = "ssh-ng";
        maxJobs = 2;
        sshUser = "remotebuild";
        sshKey = config.age.secrets.distributedUserSSHKey.path;
      }
    ];
    distributedBuilds = lib.mkForce false;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ vim wget curl btrfs-progs git ];

  users.users.remotebuild = {
    isNormalUser = true;
    openssh = { authorizedKeys.keys = distributedUserSSHKeyPub; };
  };

  services = {
    pterodactyl.wings = {
      enable = true;
      package = pkgs.pterodactyl-wings;
      openFirewall = true;
      allocatedTCPPorts = [ 5000 5001 5002 5003 5004 5005 ];
      allocatedUDPPorts = [ 5000 5001 5002 5003 5004 5005 ];
      settings = {
        api = {
          host = "127.0.0.1";
          port = 4443;
        };
        remote = "https://panel.owo.solutions";
      };
      extraConfigFile = config.age.secrets.wingsToken.path;
    };
    resolved.enable = false;
    pdns-recursor = {
      enable = true;
      settings = {
        dns64-prefix = "64:ff9b::/96";
      };
      dns = {
        port = 53;
        address =
          [ "0.0.0.0" "[::]" ];
      };
    };
    frr = {
      zebra = {
        enable = false;
        config = ''
          interface eno4
            ip ospf bfd
            ip ospf area 0.0.0.1

            ipv6 ospf6 network point-to-point
            ipv6 ospf6 bfd
            ipv6 ospf6 area 0.0.0.1
        '';
      };
      ospf = {
        enable = false;
        config = ''
          router ospf
            redistribute connected
        '';
      };
      ospf6 = {
        enable = false;
        config = ''
          router ospf6
            redistribute connected
        '';
      };
    };
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/btrfs" ];
    };
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = true;
        };
      };
    };
  };

  programs.dconf.enable = true;
  virtualisation = {
    libvirtd.enable = true;
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
      };
    };
  };

  users.users.short = {
    extraGroups = [ "wheel" "docker" "libvirtd" config.services.kubo.group ];
  };

  systemd = {
    timers = {
      "btrfs-rebalance" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Unit = "btrfs-rebalance.service";
        };
      };
    };
    services = {
      "btrfs-rebalance" = {
        script = ''
          set -eu
          ${pkgs.btrfs-progs}/bin/btrfs balance start --full-balance /btrfs
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };

  # containers = {
  #   abittorrent = {
  #     autoStart = true;
  #     privateNetwork = true;
  #     hostBridge = "vmbr0";
  #     localAddress6 = "fd6f:357c:c101::2/64";
  #     config = { config, pkgs, ... }: {
  #       services.httpd.enable = true;
  #       networking.firewall = {
  #         allowedTCPPorts = [ 80 ];
  #         allowPing = true;
  #       };
  #     };
  #   };
  # };
}
