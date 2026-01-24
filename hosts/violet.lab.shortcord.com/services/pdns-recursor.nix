{ name, pkgs, lib, config, ... }: 
let
  _nginxVirtualHosts = config.services.nginx.virtualHosts;
  _vhosts = builtins.attrNames (_nginxVirtualHosts);
in {
  networking.hosts = {
    "10.18.0.1" = _vhosts;
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
