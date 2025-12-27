{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "24.11";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-guest-agent.nix")
    ./general/all.nix
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
  };

  swapDevices = [ ];
  zramSwap.enable = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  boot = {
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

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "10-lan" = {
        matchConfig.MACAddress = "BC:24:11:6C:EB:24";
        networkConfig = {
          DHCP = "yes";
        };
      };
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
    };
  };

  services.qemuGuest.enable = true;
}
