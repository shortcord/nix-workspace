{ pkgs, config, ... }:
let fqdn = "shortcord.com";
in {
  services.nginx = {
    virtualHosts = {
      "${fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;

        root = "${pkgs.shortcord-site}";
        extraConfig = ''
          error_page 404 /index.html;
        '';

        locations."/" = {
          tryFiles = " $uri $uri/ $uri.html =404";
          index = "index.html";
        };
      };
    };
  };
}
