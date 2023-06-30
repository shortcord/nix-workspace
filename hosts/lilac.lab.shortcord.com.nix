{ name, nodes, pkgs, lib, config, ... }:
{
  system.stateVersion = "23.05";

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
        "usb_storage"
        "usbhid"
        "uas"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
  };

  networking = {
    hostName = "lilac";
    domain = "lab.shortcord.com";
    useDHCP = true;
    nameservers = [ "9.9.9.9" "2620:fe::fe" ];
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 ];
      allowPing = true;
    };
  };

  environment.systemPackages = with pkgs; [ vim wget curl ];

  systemd = {
    timers = {
      "update-dyndns-ipv6" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "update-dyndns-ipv6.service";
        };
      };
    };
    services = {
      "update-dyndns-ipv6" = {
        script = ''
          set -eu
          ${pkgs.curl}/bin/curl https://ShortCord:7m6GWrH8TtdVZLm@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv4.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
