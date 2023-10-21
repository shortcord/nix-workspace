{ pkgs, config, ... }:
let 
    bindHost = "127.0.0.2";
    port = "81";
    fqdn = "shortcord.com";
in {
  virtualisation = {
    oci-containers = {
      containers = {
        "${fqdn}" = {
          autoStart = true;
          image =
            "gitlab.shortcord.com:5050/shortcord/shortcord.com:ad3e6c0218ebcda9247b575d7f3b65bbea9a3e49";
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
