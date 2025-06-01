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
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
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
      "20-vnet" = {
        matchConfig.MACAddress = "BC:24:11:D9:22:F1";
        networkConfig = {
          DHCP = "no";
          DNS = "127.0.0.1";
          Address = [ "10.0.16.1/24" "fd97:8cb1:d65e::/64" ];
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
    tailscale = {
      extraUpFlags = [ "--login-server" "https://headscale.ns2.owo.systems" "--accept-routes" "--accept-dns" "--reset" "--advertise-routes=10.0.16.0/24" ];
    };
  };
}
