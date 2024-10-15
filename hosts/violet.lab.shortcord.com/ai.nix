{ config, pkgs, unstablePkgs, ... }:
let
  ollamaPerDir = "/var/lib/ollama";
  namespacedHost = "127.0.0.5";
  ollamaConf = config.services.ollama;
  openWebUiConf = config.services.open-webui;
  domainName = "ai.${config.networking.fqdn}";
in {
  security.acme = {
    # there has to be a better way :(
    certs = {
      "${domainName}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
    };
  };
  services = {
    ollama = { 
      enable = true;
      package = unstablePkgs.ollama;
      writablePaths = [ ollamaPerDir ];
      models = ollamaPerDir;
      listenAddress = "${namespacedHost}:11434";
      sandbox = false;
    };
    open-webui = {
      enable = true;
      package = unstablePkgs.open-webui;
      host = namespacedHost;
      port = 8080;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = "http://${ollamaConf.listenAddress}";
      };
    };
    nginx = {
      virtualHosts = {
        "${domainName}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${openWebUiConf.host}:${toString openWebUiConf.port}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}