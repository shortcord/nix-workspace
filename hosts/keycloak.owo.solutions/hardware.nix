{ name, config, lib, pkgs, modulesPath, ... }: {
  age.secrets.wireguard-mailrelay-key.file = ../../secrets/${name}/wireguard-mailrelay-key.age;

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  
  swapDevices = [ ];
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
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

  system.stateVersion = "23.05";

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/4dba3afb-b705-41fa-847c-385fc98d8a3c";
        autoResize = true;
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/042E-929B";
        fsType = "vfat";
      };
    };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowPing = true;
    };
    wireguard = {
      enable = true;
      interfaces = {
        "mail-relay" = {
          ips = [ "10.7.210.4/32" ];
          mtu = 1200;
          privateKeyFile = config.age.secrets.wireguard-mailrelay-key.path;
          peers = [{
            publicKey = "2a8w4y36L4hiG2ijQKZOfKTar28A4SPtupZnTXVUrTI=";
            persistentKeepalive = 15;
            allowedIPs = [ "10.7.210.1/32" ];
            endpoint = "66.135.9.121:51820";
          }];
        };
      };
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "00:50:56:09:46:34";
        networkConfig = {
          DHCP = "no";
          DNS = [ "127.0.0.1" "::1" ];
          Address = [ "147.135.125.70/32" "2604:2dc0:100:1b1e::31/64" ];
          Gateway = [ "51.81.11.254" "2604:2dc0:0100:1bff:00ff:00ff:00ff:00ff" ];
        };
        routes = [
          {
            Scope = "link";
            Destination = "51.81.11.254";
          }
          {
            Scope = "link";
            Destination = "2604:2dc0:0100:1bff:00ff:00ff:00ff:00ff";
          }
        ];
      };
    };
  };

  services = {
    qemuGuest.enable = true;
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ]; 
      };
    };
  };
}
