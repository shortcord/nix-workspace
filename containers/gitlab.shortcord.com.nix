{ config, pkgs, lib, ... }: {
  system.stateVersion = "23.11";

  services.forgejo = { enable = true; };

  networking.firewall = {
    allowedTCPPorts = [ 22 3000 ];
    allowPing = true;
  };
  
  #Container Only Stuff
  boot.isContainer = true;
  networking = {
    useDHCP = false;
    useHostResolvConf = false;
  };
  services.resolved.enable = true;
}
