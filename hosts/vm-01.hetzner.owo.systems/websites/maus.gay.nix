{ pkgs, config, ... }:
{
  security.acme.certs = {
    "maus.gay" = {
      dnsProvider = null;
    };
  };

  services.nginx = {
    virtualHosts = {
      "maus.gay" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/".return = "302 https://mousetail.dev";
      };
    };
  };
}
