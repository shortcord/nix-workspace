{ config, pkgs, ... }: {
  services = {
    sonarr = { enable = true; };
    nginx = {
      virtualHosts = {
        "sonarr.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8989";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
