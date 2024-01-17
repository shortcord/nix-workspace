{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "23.05";

  imports = [ 
    (modulesPath + "/profiles/qemu-guest.nix")
    ./general/all.nix
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
