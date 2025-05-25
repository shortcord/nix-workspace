{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "24.11";

  imports = [ 
    (modulesPath + "/profiles/qemu-guest.nix")
    ./general/all.nix
  ];

  swapDevices = [ ];
  zramSwap.enable = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    kernelModules = [ ];
    extraModulePackages = [ ];
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 2;
    };
    growPartition = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "xfs";
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
  }; 

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "BC:24:11:F1:B2:74";
        networkConfig = {
          DHCP = "yes";
          DNS = "127.0.0.1";
        };
      };
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = false;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 ];
      allowPing = true;
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
