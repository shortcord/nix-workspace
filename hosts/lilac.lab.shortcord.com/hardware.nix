{ pkgs, config, ... }:
{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/c9446e1f-2bec-49e8-a628-a32718ecfa89";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/3AC0-0F92";
      fsType = "vfat";
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
    kernelParams = [ "kvm-intel" "console=ttyS0" ];
    loader.timeout = 0;
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 1;
    };
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
  };
  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "00:50:56:07:31:F8";
        networkConfig = {
          DHCP = "no";
          DNS = [ "127.0.0.1" "::1" ];
          Address = [ "147.135.84.161/32" ];
          Gateway = [ "51.81.11.254" ];
        };
        routes = [
          {
            routeConfig = {
              Scope = "link";
              Destination = "51.81.11.254";
            };
          }
          # {
          #   routeConfig = {
          #     Scope = "link";
          #     Destination = "2604:2dc0:0100:1bff:00ff:00ff:00ff:00ff";
          #   };
          # }
        ];
      };
    };
  };
}
