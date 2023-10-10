{ pkgs, config, ... }: {
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
      "shortcord.com" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.2:81"; };
      };
      "owo.solutions" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.2:82"; };
      };
      "miauws.life" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        serverAliases = [ "miauws.tech" ];
        locations."/" = { return = "302 https://mousetail.dev"; };
      };
      "netbox.owo.solutions" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:8080"; };
        extraConfig = ''
          proxy_set_header X-Forwarded-Host $http_host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
      "ip.mousetail.dev" = {
        serverAliases = [ "ipv4.mousetail.dev" "ipv6.mousetail.dev" ];
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = false;
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
      "shinx.dev" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { return = "302 https://francessco.us"; };
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
      "powerdns.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:8081"; };
      };
      "powerdns-admin.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:9191"; };
      };
    };
  };
}
