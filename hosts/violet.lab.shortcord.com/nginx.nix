{ pkgs, config, ... }: {
  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    recommendedBrotliSettings = true;
    virtualHosts = {
      "wings.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://127.0.0.1:4443";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
      };
    };
  };
}
