{ name, nodes, pkgs, lib, config, ... }: {
  services = {
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
        "${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { return = "302 https://shortcord.com"; }; };
        };
      };
    };
  };
}
