{ name, pkgs, lib, config, ... }: 
let
  _jellyfin = config.services.jellyfin;
in {
  networking.hosts = lib.mkIf _jellyfin.enable {
    "10.18.0.1" = [ "jellyfin.shortcord.com" ];
  };
  services = {
    resolved.enable = false;
    pdns-recursor = {
      enable = true;
      exportHosts = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" "10.18.0.1" ];
      };
      forwardZones = { "ts.shortcord.com" = "100.100.100.100"; };
    };
  };
}
