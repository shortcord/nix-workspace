{ name, pkgs, config, ... }: {
  fileSystems = {
    "/var/lib/minio" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=893"
      ];
    };
  };
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
