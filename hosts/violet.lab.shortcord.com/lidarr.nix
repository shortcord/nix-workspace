{ config, pkgs, ... }: 
{
  services = {
    lidarr = { 
      enable = true;
      group = "torrents";
    };
    nginx = {
      virtualHosts = {
        "lidarr.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8686";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
  systemd.services.lidarr = {
    serviceConfig = {
      UMask = "0013";
    };
  };
}