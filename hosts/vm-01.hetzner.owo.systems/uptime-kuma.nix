{ config, pkgs, ... }: {
  services = {
    uptime-kuma = {
      enable = true;
      settings = {
        UPTIME_KUMA_HOST = "127.0.0.3";
        UPTIME_KUMA_PORT = "3001";
      };
    };
    nginx = {
      virtualHosts = {
        "uptime.${config.networking.fqdn}" = {
          serverAliases = [ "status.miauws.life" ];
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.3:3001";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
