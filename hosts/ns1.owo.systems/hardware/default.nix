{ name, pkgs, lib, config, ... }: {
  system.stateVersion = "26.05";

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];  
  
  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.kernels.linux_7_2;
    growPartition = true;
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [ "console=ttyS0" ];
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
  imports = [ ./disks.nix ./networking.nix ];
}
