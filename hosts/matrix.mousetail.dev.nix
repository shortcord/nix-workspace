{ name, nodes, pkgs, lib, config, colmena, ... }: {
  config = lib.mkMerge colmena.defaults;
  system.stateVersion = "23.05";

  boot.isContainer = true;

  networking = {
    hostName = "matrix";
    domain = "mousetail.dev";
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 ];
      allowPing = true;
    };
  };
}
