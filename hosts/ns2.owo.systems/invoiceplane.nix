{ name, nodes, pkgs, lib, config, ... }:
let
  host = "invoices.owo.solutions";
in {
  age.secrets = {
    invoiceplane-dbpwd = {
      file = ../secrets/${name}/invoiceplane-dbpwd.age;
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
    };
  };
  services = {
    invoiceplane = {
      webserver = "nginx";
      sites."${host}" = {
        settings = {
          IP_URL = "https://${host}";
          DISABLE_SETUP = true;
          SETUP_COMPLETED = true;
        };
        cron = {
          enable = false;
          key = "";
        };
        database = {
          host = "127.0.0.1";
          user = "invoiceplane";
          passwordFile = config.age.secrets.invoiceplane-dbpwd.path;
          name = "invoiceplane";
          createLocally = false;
        };
        enable = true;
      };
    };
    nginx.virtualHosts = {
      "${host}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
      };
    };
  };
}
