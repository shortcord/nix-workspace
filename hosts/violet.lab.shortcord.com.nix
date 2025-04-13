{ name, nodes, pkgs, lib, config, ... }: {
  age.secrets = {
    wingsToken = {
      file = ../secrets/${name}/wingsToken.age;
      owner = config.services.pterodactyl.wings.user;
      group = config.services.pterodactyl.wings.group;
    };
    wg0-private-key = {
      file = ../secrets/${name}/wg0-private-key.age;
      owner = "systemd-network";
      group = "systemd-network";
    };
  };

  system.stateVersion = "23.05";

  imports = [
    ./general/all.nix
    ./${name}/hydra.nix
    ./${name}/ipfs.nix
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
      wait-online.anyInterface = true;
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
          matchConfig.MACAddress = "98:B7:85:20:05:8A";
          networkConfig = {
            DHCP = "ipv4";
            DNS = "127.0.0.1";
            IPv6AcceptRA = false;
          };
          dhcpV4Config = {
            RouteMetric = 2048;
            Anonymize = false;
            UseDomains = false;
            UseDNS = false;
          };
          dhcpV6Config = {
            RouteMetric = 2048;
          };
          routes = [
            {
              Gateway = "_dhcp4";
              InitialCongestionWindow = 100;
              InitialAdvertisedReceiveWindow = 100;
            }
          ];
        };
        "11-wan2" = {
          matchConfig.MACAddress = "c8:1f:66:e6:7a:51";
          linkConfig.RequiredForOnline = "no";
          networkConfig = {
            DHCP = "ipv4";
            DNS = "127.0.0.1";
            IPv6AcceptRA = true;
          };
          dhcpV4Config = {
            RouteMetric = 1024;
            Anonymize = false;
            UseDomains = false;
            UseDNS = false;
          };
          dhcpV6Config = {
            RouteMetric = 1024;
          };
          routes = [{
            routeConfig = {
              Gateway = "_dhcp4";
              InitialCongestionWindow = 100;
              InitialAdvertisedReceiveWindow = 100;
            };
          }];
        };
        "20-lan" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:52";
          linkConfig.RequiredForOnline = "no";
          address = [ "10.18.0.1/24" ];
          networkConfig = {
            DHCPServer = true;
          };
          dhcpServerConfig = {
            ServerAddress = "10.18.0.1/24";
            DNS = "10.18.0.1";
            EmitDNS = true;
          };
        };
        "99-idrac" = {
          matchConfig.MACAddress = "5C:F9:DD:fA:4B:5D";
          linkConfig.RequiredForOnline = "no";
          networkConfig = {
            DHCP = "yes";
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
      "net.ipv4.route.gc_timeout" = 5;
      "net.ipv6.route.gc_timeout" = 5;
    };
  };

  networking = {
    hostId = "7f09cf4e";
    useDHCP = false;
    dhcpcd.enable = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 5201 ];
      allowedTCPPorts = [ 22 80 443 5201 ];
      allowPing = true;
      trustedInterfaces = [ 
        "vmbr0"
        config.services.tailscale.interfaceName
      ];
    };
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "enp68s0";
      internalInterfaces = [ "eno2" ];
    };
    jool = {
      enable = false;
      nat64 = {
        "default" = {
          framework = "netfilter";
          global.pool6 = "64:ff9b::/96";
        };
      };
    };
    wireguard = {
      enable = true;
      interfaces = {
        "wg0" = {
          ips = [ "10.6.210.28/32" "2001:470:e07b:2::7/128" ];
          mtu = 1380;
          listenPort = 51820;
          privateKeyFile = config.age.secrets.wg0-private-key.path;
          peers = [{
            publicKey = "ePYkBTYZaul66VdGLG70IZcCvIaZ7aSeRrkb+hskhiQ=";
            presharedKey = "a1w5c8U/uN1yVJfoB8zuw9VwDqS44SzUQKZu1ZURJ2s=";
            endpoint = "147.135.125.64:51820";
            persistentKeepalive = 15;
            allowedIPs = [ "10.6.210.1/32" "10.6.210.0/24" ];
          }];
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

  nixpkgs.config = {
    allowUnfree = true;
    ## TODO: Update these packages
    permittedInsecurePackages = [ 
      "dotnet-sdk-6.0.428"
      "aspnetcore-runtime-6.0.36"
      "qbittorrent-nox-4.6.4"
    ];
  };
  environment.systemPackages = with pkgs; [ vim wget curl btrfs-progs git ];


  security.acme = {
    # there has to be a better way :(
    certs = {
      "actual.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "bazarr.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "binarycache.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "filebrowser.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "ipfs.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "ipns.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "jackett.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "jellyfin.shortcord.com" = {
        extraDomainNames = [ "jellyfin.short.ts.shortcord.com" ];
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "komga.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "lidarr.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "proxmox.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "qbittorrent.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "radarr.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "repos.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "sonarr.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
      "wings.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
    };
  };

  services = {
    # openvpn.servers.pia = {
    #   autoStart = false;
    #   config = ''
    #     client
    #     dev tun
    #     proto udp
    #     remote 140.228.21.121 1198
    #     resolv-retry infinite
    #     nobind
    #     persist-key
    #     persist-tun
    #     cipher aes-128-cbc
    #     auth sha1
    #     tls-client
    #     remote-cert-tls server

    #     auth-user-pass ${config.age.secrets.pia-userpass.path}
    #     compress
    #     verb 1
    #     reneg-sec 0

    #     <ca>
    #     -----BEGIN CERTIFICATE-----
    #     MIIFqzCCBJOgAwIBAgIJAKZ7D5Yv87qDMA0GCSqGSIb3DQEBDQUAMIHoMQswCQYD
    #     VQQGEwJVUzELMAkGA1UECBMCQ0ExEzARBgNVBAcTCkxvc0FuZ2VsZXMxIDAeBgNV
    #     BAoTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMSAwHgYDVQQLExdQcml2YXRlIElu
    #     dGVybmV0IEFjY2VzczEgMB4GA1UEAxMXUHJpdmF0ZSBJbnRlcm5ldCBBY2Nlc3Mx
    #     IDAeBgNVBCkTF1ByaXZhdGUgSW50ZXJuZXQgQWNjZXNzMS8wLQYJKoZIhvcNAQkB
    #     FiBzZWN1cmVAcHJpdmF0ZWludGVybmV0YWNjZXNzLmNvbTAeFw0xNDA0MTcxNzM1
    #     MThaFw0zNDA0MTIxNzM1MThaMIHoMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0Ex
    #     EzARBgNVBAcTCkxvc0FuZ2VsZXMxIDAeBgNVBAoTF1ByaXZhdGUgSW50ZXJuZXQg
    #     QWNjZXNzMSAwHgYDVQQLExdQcml2YXRlIEludGVybmV0IEFjY2VzczEgMB4GA1UE
    #     AxMXUHJpdmF0ZSBJbnRlcm5ldCBBY2Nlc3MxIDAeBgNVBCkTF1ByaXZhdGUgSW50
    #     ZXJuZXQgQWNjZXNzMS8wLQYJKoZIhvcNAQkBFiBzZWN1cmVAcHJpdmF0ZWludGVy
    #     bmV0YWNjZXNzLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPXD
    #     L1L9tX6DGf36liA7UBTy5I869z0UVo3lImfOs/GSiFKPtInlesP65577nd7UNzzX
    #     lH/P/CnFPdBWlLp5ze3HRBCc/Avgr5CdMRkEsySL5GHBZsx6w2cayQ2EcRhVTwWp
    #     cdldeNO+pPr9rIgPrtXqT4SWViTQRBeGM8CDxAyTopTsobjSiYZCF9Ta1gunl0G/
    #     8Vfp+SXfYCC+ZzWvP+L1pFhPRqzQQ8k+wMZIovObK1s+nlwPaLyayzw9a8sUnvWB
    #     /5rGPdIYnQWPgoNlLN9HpSmsAcw2z8DXI9pIxbr74cb3/HSfuYGOLkRqrOk6h4RC
    #     OfuWoTrZup1uEOn+fw8CAwEAAaOCAVQwggFQMB0GA1UdDgQWBBQv63nQ/pJAt5tL
    #     y8VJcbHe22ZOsjCCAR8GA1UdIwSCARYwggESgBQv63nQ/pJAt5tLy8VJcbHe22ZO
    #     sqGB7qSB6zCB6DELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRMwEQYDVQQHEwpM
    #     b3NBbmdlbGVzMSAwHgYDVQQKExdQcml2YXRlIEludGVybmV0IEFjY2VzczEgMB4G
    #     A1UECxMXUHJpdmF0ZSBJbnRlcm5ldCBBY2Nlc3MxIDAeBgNVBAMTF1ByaXZhdGUg
    #     SW50ZXJuZXQgQWNjZXNzMSAwHgYDVQQpExdQcml2YXRlIEludGVybmV0IEFjY2Vz
    #     czEvMC0GCSqGSIb3DQEJARYgc2VjdXJlQHByaXZhdGVpbnRlcm5ldGFjY2Vzcy5j
    #     b22CCQCmew+WL/O6gzAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBDQUAA4IBAQAn
    #     a5PgrtxfwTumD4+3/SYvwoD66cB8IcK//h1mCzAduU8KgUXocLx7QgJWo9lnZ8xU
    #     ryXvWab2usg4fqk7FPi00bED4f4qVQFVfGfPZIH9QQ7/48bPM9RyfzImZWUCenK3
    #     7pdw4Bvgoys2rHLHbGen7f28knT2j/cbMxd78tQc20TIObGjo8+ISTRclSTRBtyC
    #     GohseKYpTS9himFERpUgNtefvYHbn70mIOzfOJFTVqfrptf9jXa9N8Mpy3ayfodz
    #     1wiqdteqFXkTYoSDctgKMiZ6GdocK9nMroQipIQtpnwd4yBDWIyC6Bvlkrq5TQUt
    #     YDQ8z9v+DMO6iwyIDRiU
    #     -----END CERTIFICATE-----
    #     </ca>

    #     disable-occ
    #   '';
    # };
    tailscale = {
      useRoutingFeatures = "both";
      extraUpFlags = [ "--advertise-routes" "10.18.0.0/24,10.200.1.0/24,fd6a:f1f3:23f4:1::/64" "--accept-dns=false" ];
    };
    apcupsd = {
      enable = false;
      configText = ''
        UPSNAME primary
        UPSTYPE usb
        POLLTIME 1
        NETSERVER on
        NISIP 127.0.0.1
        NISPORT 3551
        BATTERYLEVEL 10
        MINUTES 3
      '';
    };
    pterodactyl.wings = {
      enable = true;
      package = pkgs.pterodactyl-wings;
      openFirewall = true;
      allocatedTCPPorts = [ 6000 6001 6002 6003 6004 6005 ];
      allocatedUDPPorts = [ 6000 6001 6002 6003 6004 6005 ];
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
    unbound = {
      enable = false;
      settings = {
        server = {
          interface = [ "eno2" ];
          module-config = "'dns64 validator iterator'";
          # dns64-prefix = "64:ff9b::/96";
          interface-action = "eno2 allow";
        };
        forward-zone = [{
          name = ".";
          forward-addr = "9.9.9.9";
        }];
      };
    };
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
      forwardZones = {
          "short.ts.shortcord.com" = "100.100.100.100";
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
        apcupsd = {
          enable = config.services.apcupsd.enable;
          openFirewall = true;
        };
      };
    };
    nginx = {
      virtualHosts = {
        "actual.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.2:5006"; };
        };
      };
    };
    distcc = {
      enable = true;
      stats.enable = true;
      allowedClients = [ "100.64.0.0/16" ];
    };
  };

  programs = {
    dconf.enable = true;
    nix-ld.enable = true;
  };
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
        "actual" = {
          autoStart = true;
          image = "ghcr.io/actualbudget/actual-server:latest";
          volumes = [ "actual-data:/data:rw" ];
          ports = [ "127.0.0.2:5006:5006" ];
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
