{ name, config, lib, pkgs, ... }: {
   age.secrets = {
    powerdnsConfig.file = ../../secrets/${name}/powerdnsConfig.age;
    powerdns-env.file = ../../secrets/${name}/powerdns-env.age;
  };

  networking.firewall = lib.mkIf config.networking.firewall.enable {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };
  services = {
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
    };
    powerdns = {
      enable = true;
      secretFile = config.age.secrets.powerdnsConfig.path;
      extraConfig = ''
        resolver=[::1]:53
        expand-alias=yes

        local-address=88.198.125.192:53, [2a01:4f8:c012:a734::1]:53

        webserver=yes
        webserver-address=127.0.0.3
        webserver-port=8081
        webserver-allow-from=127.0.0.0/8
        api=yes
        api-key=$API_KEY

        launch=gmysql

        gmysql-port=3306
        gmysql-host=127.0.0.1
        gmysql-dbname=$SQL_DATABASE
        gmysql-user=$SQL_USER
        gmysql-password=$SQL_PASSWORD
        gmysql-dnssec=yes
      '';
    };
    nginx = lib.mkIf config.services.nginx.enable {
      virtualHosts = {
        "powerdns.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.3:8081"; };
        };
        "powerdns-admin.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.3:9191"; };
        };
      };
    };
  };
  virtualisation = {
    oci-containers = {
      containers = {
        "powerdns-admin" = {
          autoStart = true;
          image = "powerdnsadmin/pda-legacy:v0.4.1";
          volumes = [ "powerdns-admin-data:/data" ];
          environmentFiles = [ config.age.secrets.powerdns-env.path ];
          ports = [ "127.0.0.3:9191:80" ];
        };
      };
    };
  };
}
