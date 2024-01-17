{ name, pkgs, lib, config, ... }: {
  age.secrets = {
    netboxSecretKey = {
      file = ../../../secrets/${name}/netboxSecretKey.age;
      owner = "netbox";
      group = "netbox";
    };
  };
  users.users = {
    ## allow nginx user read/exec to the static directory
    "${config.services.nginx.user}" = {
      extraGroups = [ "netbox" ];
    };
  };
  systemd.services.netbox.serviceConfig.StateDirectoryMode = lib.mkForce "0755";
  systemd.services.netbox-rq.serviceConfig.StateDirectoryMode = lib.mkForce "0755";
  systemd.services.netbox-housekeeping.serviceConfig.StateDirectoryMode = lib.mkForce "0755";
  services = {
    postgresql = {
      enable = true;
      ensureUsers = [{
        name = "netbox";
        ensureDBOwnership = true;
      }];
      ensureDatabases = [ "netbox" ];
    };
    netbox = {
      enable = true;
      package = pkgs.netbox_3_6;
      listenAddress = "127.0.0.1";
      secretKeyFile = config.age.secrets.netboxSecretKey.path;
      extraConfig = ''
        ALLOWED_HOSTS = [ '*' ]
        LOGIN_REQUIRED = True
      '';
    };
    nginx = {
      virtualHosts = {
        "netbox.owo.solutions" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/static/" = {
                alias = "/var/lib/netbox/static/";
            };
            "/" = {
              proxyPass = "http://127.0.0.1:8001";
            };
          };
        };
      };
    };
  };
}
