{ name, config, pkgs, ... }: {
  age.secrets.keycloak-psql-password.file =
    ../../secrets/${name}/keycloak-psql-password.age;
  networking = { firewall = { allowedTCPPorts = [ 80 443 ]; }; };
  services = {
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://127.0.0.1:${
                toString config.services.keycloak.settings.http-port
              }";
          };
        };
      };
    };
    mysql = {
      enable = true;
      package = pkgs.mariadb;
      initialDatabases = [{ name = "keycloak"; }];
      ensureUsers = [{
        name = "keycloak";
        ensurePermissions = {
          "keycloak.*" = "ALL PRIVILEGES";
          "*.*" = "SELECT, LOCK TABLES";
        };
      }];
    };
    keycloak = {
      enable = true;
      database = {
        type = "mariadb";
        createLocally = false;
        passwordFile = config.age.secrets.keycloak-psql-password.path;
      };
      settings = {
        hostname = config.networking.fqdn;
        http-port = 8080;
        proxy = "passthrough";
        http-enabled = true;
      };
    };
  };
}
