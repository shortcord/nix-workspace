{ pkgs, config, ... }: {
  virtualisation = {
    oci-containers = {
      containers = {
        "komga" = {
          user = "1000:100";
          autoStart = true;
          image = "docker.io/gotson/komga:1.5.1";
          volumes = [
            "komga-config:/config:rw"
            "/var/lib/komga:/data:rw"
          ];
          ports = [ "127.0.0.2:25600:25600" ];
        };
      };
    };
  };
  services = {
    nginx = {
      virtualHosts = {
        "komga.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass =
              "http://127.0.0.2:25600";
          };
        };
      };
    };
  };
}
