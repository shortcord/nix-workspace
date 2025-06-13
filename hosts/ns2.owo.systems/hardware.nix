{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "22.11";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
  };

  swapDevices = [{ device = "/.swapfile"; }];
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
          matchConfig.MACAddress = "56:00:04:63:08:52";
          networkConfig = {
            DHCP = "no";
            DNS = [ "127.0.0.1" "::1" ];
            Address = [
              "66.135.9.121/23"
              "2001:19f0:1000:1512:5400:04ff:fe63:0852/64"
            ];
            Gateway = "66.135.8.1";
            IPv6AcceptRA = true;
          };
        };
      };
    };
  };

  networking = {
    useDHCP = false;
    nat = {
      enable = true;
      externalInterface = "ens3";
      internalIPs = [ "100.64.0.0/24" ];
      forwardPorts = [
        {
          proto = "tcp";
          sourcePort = "6000:6005";
          destination = "100.64.0.4:6000-6005";
        }
        {
          proto = "udp";
          sourcePort = "6000:6005";
          destination = "100.64.0.4:6000-6005";
        }
      ];
    };
    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 6000 6001 6002 6003 6004 6005 ];
      allowedTCPPorts = [ 53 22 80 443 6000 6001 6002 6003 6004 6005 ];
      allowPing = true;
      trustedInterfaces = [
        "wg1"
        config.services.tailscale.interfaceName
        "docker0"
      ];
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
