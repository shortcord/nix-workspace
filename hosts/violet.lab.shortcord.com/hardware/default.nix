{ name, pkgs, lib, config, ... }: {
  zramSwap.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.nvidia = {
    open = false;
    videoAcceleration = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
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
  imports = [ ./disks.nix ./networking.nix ];
}
