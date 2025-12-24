{ name, pkgs, lib, config, ... }: {
  zramSwap.enable = true;
  
  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
    nvidia = {
      open = false;
      videoAcceleration = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
    };
  };
  services.xserver = {
    enable = false;
    videoDrivers = [ "nvidia" ];
  };
  boot = {
    growPartition = true;
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
