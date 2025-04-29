{ config, pkgs, ... }: {
  security.acme.certs."radarr.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
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
          enableACME = true;
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
      UMask = "0013";
    };
  };
}
