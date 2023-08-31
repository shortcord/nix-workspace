{ name, nodes, pkgs, lib, config, ... }:
let
  distributedUserSSHKeyPub = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnmaQeov9+Xv7z/ulQ0zPVDN3ZKW4AUK8IyoVkbUKQa"
  ];
in
{
  age.secrets = {
    distributedUserSSHKey.file = ../secrets/general/distributedUserSSHKey.age;
  };

  system.stateVersion = "23.05";

  imports = [
    ./general/dyndns-ipv4.nix
    ./general/dyndns-ipv6.nix
    ./general/promtail.nix
    ./${name}/hydra.nix
    ./${name}/ipfs.nix
    ./${name}/minio.nix
    ./${name}/nginx.nix
    ./${name}/jellyfin.nix
    ./${name}/gallery-dl-sync.nix
    ./${name}/deluged.nix
    ./${name}/owncast.nix
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
    "/var/lib/ipfs" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=605"
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
    "/var/lib/minio" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=893"
      ];
    };
    "/var/jellyfin" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=896"
      ];
    };
    "/var/gallery-dl" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=890"
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
          };
          extraConfig = ''
            [DHCPPrefixDelegation]
            UplinkInterface=eno1
            SubnetId=0
            Announce=yes
          '';
        };
        "30-home" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:54";
          linkConfig.RequiredForOnline = "no";
          address = [ "192.168.15.2/24" ];
          networkConfig = {
            DHCP = "no";
            DNS = "no";
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
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 5201 ];
      allowedTCPPorts = [ 22 80 443 5201 ];
      allowPing = true;
      trustedInterfaces = [ "eno1" "eno2" "eno4" ];
    };
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "eno1";
      internalInterfaces = [ "eno2" ];
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
    resolved.enable = false;
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" "10.18.0.1" ];
      };
    };
    dhcpd4 = {
      enable = true;
      authoritative = true;
      interfaces = [ "eno2" ];
      extraConfig = ''
        option subnet-mask 255.255.255.0;
        option broadcast-address 10.18.0.255;
        option routers 10.18.0.1;
        option domain-name-servers 10.18.0.1;
        option domain-name "lab.shortcord.com";
        subnet 10.18.0.0 netmask 255.255.255.0 {
          range 10.18.0.5 10.18.0.200;
        }
      '';
      machines = [
        {
          hostName = "lilac.lab.shortcord.com";
          ipAddress = "10.18.0.2";
          ethernetAddress = "14:18:77:5b:a9:87";
        }
        {
          hostName = "amethyst.lab.shortcord.com";
          ipAddress = "10.18.0.3";
          ethernetAddress = "18:66:da:5f:d8:ff";
        }
      ];
    };
    frr = {
      zebra = {
        enable = true;
        config = ''
          interface eno4
            ip ospf bfd
            ip ospf area 1
            ipv6 ospf6 network point-to-point
            ipv6 ospf6 bfd
        '';
      };
      ospf = {
        enable = true;
        config = ''
          router ospf
            redistribute connected
            area 1 shortcut default
        '';
      };
      ospf6 = {
        enable = true;
        config = ''
          router ospf6
            redistribute connected
            interface eno4 area 1
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
}
