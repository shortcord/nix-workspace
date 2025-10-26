{ name, pkgs, lib, config, ... }: {

  age.secrets = {
    wingsToken = {
      file = ../secrets/${name}/wingsToken.age;
      owner = config.services.pterodactyl.wings.user;
      group = config.services.pterodactyl.wings.group;
    };
  };

  services = {
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
    pterodactyl.wings = {
      enable = true;
      package = pkgs.pterodactyl-wings;
      openFirewall = true;
      allocatedTCPPorts = [ 6000 6001 6002 6003 6004 6005 ];
      allocatedUDPPorts = [ 6000 6001 6002 6003 6004 6005 ];
      settings = {
        system.user.rootless = {
          enabled = true;
          container_uid = config.users.users."pterodactyl".uid;
          container_gid = config.users.groups."pterodactyl".gid;
        };
        api = {
          host = "127.0.0.1";
          port = 4443;
        };
        remote = "https://panel.owo.solutions";
      };
      extraConfigFile = config.age.secrets.wingsToken.path;
    };
  };
}
