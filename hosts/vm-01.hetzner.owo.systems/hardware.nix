{ ... }: {
  boot = {
    initrd = {
      availableKernelModules =
        [ "ata_piix" "virtio_pci" "virtio_scsi" "xhci_pci" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
    loader = {
      grub = {
        enable = true;
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_30515526";
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/79bdfbec-983a-41ac-9603-a207beae1f19";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/DD73-4F08";
      fsType = "vfat";
    };
  };

  swapDevices = [ ];
  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = false;
  hardware.cpu.intel.updateMicrocode = false;
}
