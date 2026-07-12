{ config, pkgs, lib, ... }:
{
  services = {
    radarr = { 
      enable = true;
      group = "torrents";
    };
    nginx = {
      virtualHosts = {
        "radarr.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          useACMEHost = "${config.networking.fqdn}";

          locations."/" = {
            proxyPass = "http://127.0.0.1:7878";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
  systemd.services.radarr = {
    serviceConfig = {
      UMask = lib.mkForce "0013";
    };
  };
}
