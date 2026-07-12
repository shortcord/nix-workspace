{ config, pkgs, lib, ... }:
{
  services = {
    bazarr = { 
      enable = true;
      group = "torrents";
    };
    nginx = {
      virtualHosts = {
        "bazarr.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          useACMEHost = "${config.networking.fqdn}";
          
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.bazarr.listenPort}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
  systemd.services.bazarr = {
    serviceConfig = {
      UMask = lib.mkForce "0013";
    };
  };
}