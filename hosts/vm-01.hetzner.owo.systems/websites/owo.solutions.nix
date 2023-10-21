{ pkgs, config, ... }:
let 
    bindHost = "127.0.0.2";
    port = "82";
    fqdn = "owo.solutions";
in {
  virtualisation = {
    oci-containers = {
      containers = {
        "${fqdn}" = {
          autoStart = true;
          image =
            "gitlab.shortcord.com:5050/owo.solutions/homepage:21d37ec71927af3ca6f0fce52e702e323a468fcb";
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
        locations."/" = { proxyPass = "http://${bindHost}:${port}"; };
      };
    };
  };
}
