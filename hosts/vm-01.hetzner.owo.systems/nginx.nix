{ pkgs, lib, config, ... }: {
  networking.firewall = lib.mkIf config.networking.firewall.enable {
    allowedTCPPorts = [ 80 443 ];
  };

  security.acme.certs = {
    "ip.mousetail.dev" = {
      inheritDefaults = true;
      dnsProvider = "pdns";
      environmentFile = config.age.secrets.acmeCredentialsFile.path;
      webroot = null;
    };
  };

  services.nginx = {
    package = pkgs.nginxQuic;
    enable = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    recommendedBrotliSettings = true;
    virtualHosts = {
      "ip.mousetail.dev" = {
        serverAliases = [ "ipv4.mousetail.dev" "ipv6.mousetail.dev" "tailscale.mousetail.dev" ];
        kTLS = true;
        http2 = true;
        http3 = true;
        addSSL = true;
        enableACME = true;
        locations."/" = { return = "200 $remote_addr"; };
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
      "owo.gallery" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { return = "302 https://mousetail.dev"; };
      };
      "grafana.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${
              toString config.services.grafana.settings.server.http_addr
            }:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
