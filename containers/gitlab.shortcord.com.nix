{ config, pkgs, lib, ... }: {
  system.stateVersion = "25.11";

  imports = [
    ./general/container-base.nix
  ];

  services = {
    forgejo = { enable = true; };
  };

  networking.firewall = {
    allowedTCPPorts = [ 22 3000 ];
    allowPing = true;
  };
}
