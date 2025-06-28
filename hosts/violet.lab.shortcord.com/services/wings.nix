{ lib, pkgs, config, name, ... }: {
  age.secrets = {
    wingsToken = {
      file = ../../../secrets/${name}/wingsToken.age;
      owner = config.services.pterodactyl.wings.user;
      group = config.services.pterodactyl.wings.group;
    };
  };
  security.acme.certs."wings.${config.networking.fqdn}" = {
    inheritDefaults = true;
    dnsProvider = "pdns";
    environmentFile = config.age.secrets.acmeCredentialsFile.path;
    webroot = null;
  };
  services = {
    pterodactyl.wings = {
      enable = true;
      package = pkgs.pterodactyl-wings;
      openFirewall = true;
      allocatedTCPPorts = lib.range 6000 6050;
      allocatedUDPPorts = lib.range 6000 6050;
      settings = {
        api = {
          host = "127.0.0.1";
          port = 4443;
        };
        remote = "https://panel.owo.solutions";
      };
      extraConfigFile = config.age.secrets.wingsToken.path;
    };
    nginx = {
      virtualHosts = {
        "wings.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://127.0.0.1:4443";
            extraConfig = ''
              client_max_body_size 0;
            '';
          };
        };
      };
    };
  };
}
