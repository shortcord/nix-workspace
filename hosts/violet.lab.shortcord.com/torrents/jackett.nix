{ config, pkgs, ... }: 
{
   services = {
    jackett = { 
      package = pkgs.jackett.overrideAttrs (self: super: {
        # Because the test suite for jacket 
        # depends on current date, which is fucking stupid
        doCheck = false;
      });
      enable = true;
    };
    nginx = {
      virtualHosts = {
        "jackett.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9117";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}