{ name, nodes, pkgs, lib, config, ... }:
let
  host = "invoices.owo.solutions";
  passwordFile = pkgs.writeText "invoiceplanePasswd" "password";
in {
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
          passwordFile = passwordFile;
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
