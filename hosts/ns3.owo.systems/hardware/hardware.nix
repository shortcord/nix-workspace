{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "24.11";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
  };

  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = false;

  boot = {
    growPartition = true;
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [ "ata-piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };
    initrd = {
      availableKernelModules =
        [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
      kernelModules = [ ];
    };
  };

  systemd = {
    network = {
      wait-online.anyInterface = true;
      enable = true;
      networks = {
        "10-wan" = {
          matchConfig.MACAddress = "56:00:05:7c:f9:0a";
          networkConfig = {
            DHCP = "no";
            DNS = [ "127.0.0.1" "::1" ];
            Address = [
              "144.202.94.86/23"
              "2001:19f0:8001:07db:5400:05ff:fe7c:f90a/64"
            ];
            Gateway = "144.202.94.1";
            IPv6AcceptRA = true;
          };
        };
      };
    };
  };

  networking = {
    useDHCP = false;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 22 80 443 ];
      allowPing = true;
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };
  };

  services = {
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
    };
  };
}
