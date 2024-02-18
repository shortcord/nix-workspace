{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "23.05";

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ./general/all.nix ];

  swapDevices = [ ];
  zramSwap.enable = true;
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    kernelModules = [ ];
    extraModulePackages = [ ];
    initrd = {
      kernelModules = [ ];
      availableKernelModules =
        [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    };
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    growPartition = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8a54b50a-b8fa-4093-b4c4-55c0db8ecbab";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/01D7-974D";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/13c0db3d-b4f0-448f-bc9b-a7604731fb48";
      fsType = "xfs";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  nix = {
    buildMachines = [{
      hostName = "localhost";
      systems = [ "x86_64-linux" "i686-linux" ];
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
      maxJobs = 8;
    }];
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "12:22:95:0e:10:6c";
        networkConfig = {
          DHCP = "ipv6";
          IPv6AcceptRA = true;
        };
      };
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
    };
  };

  services = {
    qemuGuest.enable = true;
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
          openFirewall = true;
        };
      };
    };
  };

  age.secrets.nix-serve.file = ../secrets/${name}/nix-serve.age;
  services = {
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
        "cache.${config.networking.fqdn}" = {
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
        "${config.networking.fqdn}" = lib.mkIf config.services.hydra.enable {
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
      };
    };
    nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets.nix-serve.path;
      bindAddress = "127.0.0.1";
      port = 5000;
    };
    hydra = {
      enable = true;
      listenHost = "127.0.0.1";
      hydraURL = "https://${config.networking.fqdn}";
      notificationSender = "hydra@${config.networking.fqdn}";
      buildMachinesFiles = [ ];
      useSubstitutes = true;
    };
  };
}
