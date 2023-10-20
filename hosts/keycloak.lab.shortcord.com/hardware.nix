{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  boot = { tmp.useTmpfs = true; };

  system.stateVersion = "23.05";

  services = {
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "keycloak.lab.shortcord.com" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}";
          };
        };
      };
    };
    keycloak = {
      enable = true;
      database = {
        type = "postgresql";
        createLocally = true;
        passwordFile = "/var/test";
      };
      settings = {
        hostname = "keycloak.lab.shortcord.com";
        http-port = 8080;
        proxy = "passthrough";
        http-enabled = true;
      };
    };
  };

  networking = {
    hostName = "keycloak";
    domain = "lab.shortcord.com";
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
    };
  };
}
