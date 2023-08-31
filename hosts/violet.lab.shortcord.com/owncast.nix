{ name, pkgs, config, lib, ... }:
let cfg = config.services.owncast;
in {
  services = {
    owncast = {
      enable = false;
      listen = "127.0.0.1";
      port = 9010;
    };
    nginx = {
      virtualHosts = lib.mkIf cfg.enable {
        "stream.miauws.life" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://${cfg.listen}:${toString cfg.port}"; };
        };
      };
    };
  };
}
