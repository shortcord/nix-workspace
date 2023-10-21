{ config, lib, pkgs, ... }: 
let
  cfg = config.services.uiptime-kuma;
in {
  services = {
    uptime-kuma = {
      enable = true;
      settings = {
        UPTIME_KUMA_HOST = "127.0.0.3";
        UPTIME_KUMA_PORT = "3001";
      };
    };
    nginx = lib.mkIf config.services.nginx.enable {
      virtualHosts = {
        "uptime.${config.networking.fqdn}" = {
          serverAliases = [ "status.miauws.life" ];
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${cfg.settings.UPTIME_KUMA_HOST}:${cfg.settings.UPTIME_KUMA_PORT}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
