{ pkgs, lib, config, ... }: {
  networking.firewall = lib.mkIf config.networking.firewall.enable {
    allowedTCPPorts = [ 80 443 ];
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
        serverAliases = [ "ipv4.mousetail.dev" "ipv6.mousetail.dev" ];
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
      "freekobolds.com" = {
        serverAliases = [ "www.freekobolds.com" ];
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          return = "302 https://www.twitch.tv/touchscalytail";
        };
      };
      "owo.gallery" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { return = "302 https://mousetail.dev"; };
      };
      "pawtism.dog" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { return = "302 https://estrogen.dog"; };
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
