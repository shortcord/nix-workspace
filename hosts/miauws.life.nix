{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "23.05";

  imports = [ 
    (modulesPath + "/profiles/qemu-guest.nix")
    ./general/all.nix
    ./${name}/mailserver.nix
    ./${name}/mastodon.nix
  ];

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
      device = "/dev/disk/by-uuid/9ca4a749-ee3c-4d0c-ae8b-69e64256766d";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/9979-E152";
      fsType = "vfat";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "00:50:56:09:0B:59";
        networkConfig = {
          DHCP = "no";
          DNS = [ "127.0.0.1" "::1" ];
          Address = [ "51.81.23.224/32" "2604:2dc0:100:1b1e::30/64" ];
          Gateway = [ "51.81.11.254" "2604:2dc0:0100:1bff:00ff:00ff:00ff:00ff" ];
        };
        routes = [
          {
            routeConfig = {
              Scope = "link";
              Destination = "51.81.11.254";
            };
          }
          {
            routeConfig = {
              Scope = "link";
              Destination = "2604:2dc0:0100:1bff:00ff:00ff:00ff:00ff";
            };
          }
        ];
      };
    };
  };

  networking = {
    hostName = "miauws";
    domain = "life";
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 ];
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
}
