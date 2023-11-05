{ name, nodes, pkgs, lib, config, ... }: {
  age.secrets.powerdnsConfig.file = ../../secrets/${name}/powerdnsConfig.age;

  services = {
    mysqlBackup = {
      enable = true;
      # Backup daily
      calendar = "*-*-* 00:00:00";
      singleTransaction = true;
      databases = [
        "powerdns"
      ];
    };
    mysql = {
      package = pkgs.mariadb;
      enable = true;
      replication = {
        role = "master";
        serverId = 2;
        ## This information is only here to prevent the init script
        # from erroring out during deployment 
        masterUser = "replication_user";
        masterPassword = "temppassword";
        slaveHost = "10.7.210.2";
      };
    };
    powerdns = {
      enable = true;
      secretFile = config.age.secrets.powerdnsConfig.path;
      extraConfig = ''
        resolver=[::1]:53
        expand-alias=yes

        local-address=66.135.9.121:53, [2001:19f0:1000:1512:5400:04ff:fe63:0852]:53

        webserver=yes
        webserver-address=127.0.0.1
        webserver-port=8081
        webserver-allow-from=127.0.0.1,::1
        api=yes
        api-key=$API_KEY

        launch=gmysql

        gmysql-port=3306
        gmysql-host=$SQL_HOST
        gmysql-dbname=$SQL_DATABASE
        gmysql-user=$SQL_USER
        gmysql-password=$SQL_PASSWORD
        gmysql-dnssec=yes
      '';
    };
    nginx = {
      virtualHosts = {
        "powerdns.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8081"; };
        };
      };
    };
  };
}
