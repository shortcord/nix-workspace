{ name, pkgs, config, ... }: {
  age.secrets.minioSecret.file = ../../secrets/${name}/minioSecret.age;
  services = {
    nginx = {
      virtualHosts = {
        "minio.${config.networking.fqdn}" = {
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
            proxyPass = "http://${config.services.minio.listenAddress}";
          };
        };
      };
    };
    minio = {
      enable = true;
      rootCredentialsFile = config.age.secrets.minioSecret.path;
      listenAddress = "127.0.0.1:9000";
      consoleAddress = "127.0.0.1:9001";
      region = "us-01";
    };
  };
}
