{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "23.11";

  imports = [ ./general/dyndns.nix ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/9671d973-8de0-4b34-844f-483db73b9b16";
      fsType = "xfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/F6C2-C265";
      fsType = "vfat";
    };
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "10-wan" = {
          matchConfig.MACAddress = "b8:ca:3a:b5:db:4b";
          networkConfig = {
            DHCP = "ipv4";
            DNS = "127.0.0.1";
            IPv6AcceptRA = true;
          };
        };
        "20-lan" = {
          matchConfig.MACAddress = "1c:fd:08:7b:7e:84";
          linkConfig = {
            RequiredForOnline = false;
          };
          address = [ "10.18.0.1/24" ];
          networkConfig = {
            IPv6SendRA = true;
            DHCPPrefixDelegation = true;
            IPv6AcceptRA = false;
            DHCPServer = true;
            ConfigureWithoutCarrier = true;
          };
          dhcpPrefixDelegationConfig = {
            UplinkInterface = "eno1";
            SubnetId = 0;
            Announce = true;
          };
          dhcpServerConfig = {
            ServerAddress = "10.18.0.1/24";
            DNS = "10.18.0.1";
            EmitDNS = true;
          };
          ipv6SendRAConfig = {
            DNS = "_link_local";
            EmitDNS = true;
          };
        };
        "30-home" = {
          matchConfig.MACAddress = "1c:fd:08:7b:7e:85";
          linkConfig = {
            RequiredForOnline = false;
          };
          address = [ "192.168.15.1/24" ];
          networkConfig = {
            DHCP = "no";
            DNS = "no";
            IPv6AcceptRA = false;
            ConfigureWithoutCarrier = true;
          };
        };
      };
    };
  };

  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    growPartition = true;
    kernelModules = [ "jool" ];
    extraModulePackages = [ pkgs.linuxKernel.packages.linux_6_1.jool ];
    kernelParams = [ "kvm-intel" ];
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 5;
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
      trustedInterfaces = [ "eno1" "enp1s0f0" "enp1s0f1" ];
    };
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "eno1";
      internalInterfaces = [ "enp1s0f0" "enp1s0f1" ];
    };
    jool = {
      enable = true;
      nat64 = {
        "default" = {
          framework = "netfilter";
          global.pool6 = "64:ff9b::/96";
        };
      };
    };
  };

  services = {
    resolved.enable = false;
    unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "enp1s0f0" "enp1s0f1" ];
          module-config = "'dns64 validator iterator'";
          dns64-prefix = "64:ff9b::/96";
          interface-action = [ "enp1s0f0 allow" "enp1s0f1 allow" ];
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = "9.9.9.9";
          }
        ];
      };
    };
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
    };
  };

  age.secrets.pdnsApiKey.file = ../secrets/general/pdnsApiKey.age;
}
