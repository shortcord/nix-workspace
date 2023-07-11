{ name, nodes, pkgs, lib, config, ... }:
let
  distributedUserSSHKeyPub = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnmaQeov9+Xv7z/ulQ0zPVDN3ZKW4AUK8IyoVkbUKQa"
  ];
in {
  age.secrets = {
    pdnsApiKey.file = ../secrets/general/pdnsApiKey.age;
    distributedUserSSHKey.file = ../secrets/general/distributedUserSSHKey.age;
    nix-serve.file = ../secrets/${name}/nix-serve.age;
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
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
      trustedInterfaces = [ "eno1" "eno2" ];
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
    kubo = {
      enable = true;
      emptyRepo = true;
      enableGC = true;
      localDiscovery = false;
      settings = {
        PublicGateways = {
          "${config.networking.fqdn}" = {
            Paths = [ "/ipfs" "/ipns" ];
            UseSubdomains = true;
          };
        };
        Bootstrap = [
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN"
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa"
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb"
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt"
          "/ip4/104.131.131.82/tcp/4001/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ"
          "/ip4/104.131.131.82/udp/4001/quic/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ"

          ## ipfs-01.owo.systems
          "/dns4/ipfs-01.owo.systems/tcp/4001/p2p/12D3KooWNGmh5EBpPBXGGcFnrMtBW6u9Z61HgyHAobjo2ANhq1kL"
          "/dns4/ipfs-01.owo.systems/udp/4001/quic/p2p/12D3KooWNGmh5EBpPBXGGcFnrMtBW6u9Z61HgyHAobjo2ANhq1kL"
          "/dns6/ipfs-01.owo.systems/tcp/4001/p2p/12D3KooWNGmh5EBpPBXGGcFnrMtBW6u9Z61HgyHAobjo2ANhq1kL"
          "/dns6/ipfs-01.owo.systems/udp/4001/quic/p2p/12D3KooWNGmh5EBpPBXGGcFnrMtBW6u9Z61HgyHAobjo2ANhq1kL"
        ];
        Peering = {
          Peers = [
            {
              Addrs = [ ];
              ID = "12D3KooWM63pJ1xhDjqKvH8bEyzowwmfB5tP9UndMP2T2WjDBF7Y";
            }
            {
              Addrs = [ ];
              ID = "12D3KooWDJCyi3EAVBeisRkrRGtEPjEHNA3CKsmwbWbg5mM9eqvZ";
            }
            {
              Addrs = [
                "/ip6/2a01:4ff:f0:c73c::1/udp/4001/quic/p2p/12D3KooWJTJoJZ49CgoqYe4JnUfXaqDPYiG5bm1ssN6X4v8n9FF2/p2p-circuit"
              ];
              ID = "12D3KooWJo2f5EmnUmZFeWxVDHUKdpZmhQ9pVdJ2eQToxNyF5WNm";
            }
            {
              Addrs = [ "/dns6/ipfs1.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWFkQFKVSgmDfUggx5de5wSbAtfegBnashkP8VN8rESRUX";
            }
            {
              Addrs = [ "/dns6/ipfs.home.bsocat.net/tcp/4001" ];
              ID = "12D3KooWGHPei7QWiX8vJjHgEkoC4QDWcGKdJf9bE8noP1dAWS21";
            }
            {
              Addrs = [ "/dns6/ipfs2.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWLSr7JRSYooakhq58vZowUcCaW4ff31tHaGTrWDDaCL8W";
            }
            {
              Addrs = [ "/dns6/gnutoo.home.bsocat.net/tcp/4001" ];
              ID = "12D3KooWNoPhenCQSsdfKJvJ8g2R1bHbw7M7s5arykhqJCVd5F2B";
            }
            {
              Addrs = [ "/dns6/dl.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWQvvJkr8fqUAJWcwe6Tysng3AQyKtSBnTG85rW5vm4B67";
            }
            {
              Addrs = [ "/dns6/ipfs3.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWS3ZiwYPxL4iB3xh32oQs7Cm61ZN7sCsQXhvTGyfybn91";
            }
          ];
        };
        Datastore = { StorageMax = "1000GB"; };
        Addresses = {
          API = [ "/ip4/127.0.0.1/tcp/5001" ];
          Gateway = [ "/ip4/127.0.0.1/tcp/8080" ];
        };
      };
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedBrotliSettings = true;
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
        "hydra.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://${config.services.hydra.listenHost}:${
                toString config.services.hydra.port
              }";
          };
        };
        "ipfs.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = { proxyPass = "http://localhost:8080"; };
        };
        "ipns.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = { proxyPass = "http://localhost:8080"; };
        };
      };
    };
    hydra = {
      enable = true;
      listenHost = "localhost";
      hydraURL = "https://hydra.${config.networking.fqdn}";
      notificationSender = "hydra@${config.networking.fqdn}";
      useSubstitutes = false;
      extraConfig = ''
        <git-input>
          timeout = 3600
        </git-input>
      '';
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

  users.users.short = { extraGroups = [ "wheel" "docker" "libvirtd" ]; };

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
      "btrfs-rebalance" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Unit = "btrfs-rebalance.service";
        };
      };
    };
    services = {
      "update-dyndns-ipv4" = {
        script = ''
          set -eu
          source ${config.age.secrets.pdnsApiKey.path}
          ${pkgs.curl}/bin/curl https://''${API_USERNAME}:''${API_PASSWORD}@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv4.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
      "update-dyndns-ipv6" = {
        script = ''
          set -eu
          source ${config.age.secrets.pdnsApiKey.path}
          ${pkgs.curl}/bin/curl https://''${API_USERNAME}:''${API_PASSWORD}@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv4.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
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
