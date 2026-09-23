{ name, pkgs, lib, config, ... }: 
let
  _nginxVirtualHosts = config.services.nginx.virtualHosts;
  _vhosts = builtins.attrNames (_nginxVirtualHosts);
in {
  networking.hosts = {
    "10.18.0.1" = _vhosts;
    "127.0.0.1" = [ "localhost" ];
    "::1" = [ "localhost" ];

    # Prevent Nix from setting this to the fqdn
    # cause loopback addresses are just that, locally addressable loopback
    # pretty worthless for a gateway
    # this does mean anything addressed for violet.lab.shortcord.com coming from this host will resolve through tailscale's interface
    # but honestly that's not a major issue
    "127.0.0.2" = lib.mkForce [];
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
      forwardZonesRecurse = { "ts.shortcord.com" = "100.100.100.100"; };
    };
  };
}
