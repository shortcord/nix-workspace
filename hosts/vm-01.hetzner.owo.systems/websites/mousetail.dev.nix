{ pkgs, config, ... }:
let 
    bindHost = "127.0.0.2";
    port = "83";
    fqdn = "mousetail.dev";
in {
  virtualisation = {
    oci-containers = {
      containers = {
        "${fqdn}" = {
          autoStart = true;
          image =
            "gitlab.shortcord.com:5050/mousetail-dev/mousetail.dev:06f7a1a3419bc3ffa1e3cd047c3377be01b80ffb";
          ports = [ "${bindHost}:${port}:80" ];
        };
      };
    };
  };
  services.nginx = {
    virtualHosts = {
      "${fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { 
          proxyPass = "http://${bindHost}:${port}";
        };
      };
    };
  };
}
