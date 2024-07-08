{ name, nodes, pkgs, lib, config, ... }:
let hsConf = config.services.headscale;
in {
  services = {
    headscale = {
      enable = true;
      address = "127.0.0.5";
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedBrotliSettings = true;
      virtualHosts = {
        "headscale.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = { proxyPass = "http://${hsConf.address}:${hsConf.port}"; };
          };
        };
      };
    };
  };
}
