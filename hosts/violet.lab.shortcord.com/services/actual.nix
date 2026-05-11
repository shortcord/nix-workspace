{ name, pkgs, lib, config, ... }: {
  services.nginx = {
    virtualHosts = {
      "actual.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        useACMEHost = "${config.networking.fqdn}";

        locations."/" = { proxyPass = "http://127.0.0.2:5006"; };
      };
    };
  };
  virtualisation = {
    oci-containers = {
      containers = {
        "actual" = {
          autoStart = true;
          image = "ghcr.io/actualbudget/actual-server:latest";
          volumes = [ "actual-data:/data:rw" ];
          ports = [ "127.0.0.2:5006:5006" ];
        };
      };
    };
  };
}
