{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "25.11";

  imports = [ ./general/all.nix ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "xfs";
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
    "/data" = {
      device = "/dev/disk/by-label/DATA";
      fsType = "xfs";
    };
  };

  systemd = {
    network = {
      enable = true;
      wait-online.anyInterface = true;
      networks = {
        "10-lan" = {
          matchConfig.MACAddress = "14:18:77:5b:a9:87";
          linkConfig = { RequiredForOnline = true; };
          networkConfig = {
            DHCP = "yes";
            DNS = "127.0.0.1";
          };
        };
        "20-storage" = {
          matchConfig.MACAddress = "14:18:77:5b:a9:88";
          linkConfig = { 
            RequiredForOnline = false;
            MTUBytes = 9200;
          };
          address = [ "10.65.0.2/30" ];
          networkConfig = {
            DHCP = "no";
            DNS = "no";
            IPv6AcceptRA = false;
          };
        };
      };
    };
  };

  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  boot = {
    growPartition = true;
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [ "kvm-intel" ];
    loader = {
      grub.enable = false;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
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
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = false;
      allowPing = true;
    };
  };

  services = {
    nfs.server = {
      enable = true;
      nproc = 128;
      exports = ''
          /data/vmdata 10.65.0.1/32(rw,no_root_squash,async,rw,no_subtree_check)
      '';
    };
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
