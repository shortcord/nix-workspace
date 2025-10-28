{ config, pkgs, unstablePkgs, lib, ... }:
let
  ollamaPerDir = "/var/lib/ollama";
  namespacedHost = "127.0.0.5";
  openWebUiConf = config.services.open-webui;
  domainName = "ai.mousetail.dev";

  open-webui-pkg = pkgs.callpackage ./packages/open-webui {};
in {
  nixpkgs.config.allowUnfree = true;
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
    open-webui = {
      enable = true;
      package = unstablePkgs.open-webui;
      host = namespacedHost;
      port = 8080;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = "http://maus.ts.shortcord.com:11434";
      };
    };
    nginx = {
      upstreams = {
        "ollama" = {
          servers = {
            "${openWebUiConf.host}:${toString openWebUiConf.port}" = { };
          };
        };
      };
      virtualHosts = {
        "${domainName}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { 
            proxyPass = "http://ollama";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };
    };
  };
}