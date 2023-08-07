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
      "proxmox.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "https://10.18.0.3:8006";
          proxyWebsockets = true;
        };
      };
      "minio-admin.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;

        extraConfig = ''
          ignore_invalid_headers off;
          client_max_body_size 0;
          proxy_buffering off;
          proxy_request_buffering off;
        '';

        locations."/" = {
          proxyPass = "http://${config.services.minio.consoleAddress}";
          extraConfig = ''
            proxy_set_header X-NginX-Proxy true;
            chunked_transfer_encoding off;
          '';
        };
      };
    };
  };
}
