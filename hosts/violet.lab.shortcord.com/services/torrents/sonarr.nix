{ config, pkgs, lib, ... }:
{
  services = {
    sonarr = {
      enable = true;
      group = "torrents";
    };
    nginx = {
      virtualHosts = {
        "sonarr.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          useACMEHost = "${config.networking.fqdn}";

          locations."/" = {
            proxyPass = "http://127.0.0.1:8989";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
  systemd.services.sonarr = {
    serviceConfig = {
      UMask = lib.mkForce "0013";
    };
  };
}
