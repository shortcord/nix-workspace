{ name, pkgs, lib, config, ... }: {
  security.acme.certs = {
    "actual.${config.networking.fqdn}" = {
      inheritDefaults = true;
      dnsProvider = "pdns";
      environmentFile = config.age.secrets.acmeCredentialsFile.path;
      webroot = null;
    };
  };
  services.nginx = {
    virtualHosts = {
      "actual.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
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
