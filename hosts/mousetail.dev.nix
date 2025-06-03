{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "24.11";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-guest-agent.nix")
    ./general/all.nix
  ];

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
