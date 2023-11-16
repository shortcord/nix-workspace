{ config, pkgs, ... }:
{
  networking.firewall = {
    allowedUDPPorts = [ 1900 7359 ];
  };
  services = {
    jellyfin = {
      enable = true;
    };
    nginx = {
      virtualHosts = {
        "jellyfin.shortcord.com" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          extraConfig = ''
            client_max_body_size 20M;

            add_header X-Frame-Options "SAMEORIGIN";
            add_header X-XSS-Protection "0"; # Do NOT enable. This is obsolete/dangerous
            add_header X-Content-Type-Options "nosniff";
            add_header Cross-Origin-Opener-Policy "same-origin" always;
            add_header Cross-Origin-Embedder-Policy "require-corp" always;
            add_header Cross-Origin-Resource-Policy "same-origin" always;
            add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;
            add_header Origin-Agent-Cluster "?1" always;
          '';

          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:8096";
              extraConfig = ''
                proxy_buffering off;
              '';
            };
            "/socket" = {
              proxyPass = "http://127.0.0.1:8096";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };
  users.users.jellyfin = {
    extraGroups = [ "users" ];
  };
}
