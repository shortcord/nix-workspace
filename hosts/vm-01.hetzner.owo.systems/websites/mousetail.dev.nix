{ pkgs, config, ... }:
let 
    bindHost = "127.0.0.2";
    port = "83";
    fqdn = "mousetail.dev";
in {
  virtualisation = {
    oci-containers = {
      containers = {
        "${fqdn}" = {
          autoStart = true;
          image =
            "gitlab.shortcord.com:5050/mousetail-dev/mousetail.dev:06f7a1a3419bc3ffa1e3cd047c3377be01b80ffb";
          ports = [ "${bindHost}:${port}:80" ];
        };
      };
    };
  };
 security.acme = {
    certs = {
      "ai.${fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
    };
 };
  services.nginx = {
    virtualHosts = {
      "${fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { 
          proxyPass = "http://${bindHost}:${port}";
        };
      };
      "ai.${fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = { 
            proxyPass = "https://ai.violet.lab.shortcord.com";
            proxyWebsockets = true;
            # This gets included after the extraConfig, god why
            recommendedProxySettings = false;
            extraConfig = ''
              proxy_set_header Host ai.violet.lab.shortcord.com;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host ai.violet.lab.shortcord.com;
              proxy_set_header X-Forwarded-Server ai.violet.lab.shortcord.com;
            '';
          };
      };
    };
  };
}
