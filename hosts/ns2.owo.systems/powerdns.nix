{ name, nodes, pkgs, lib, config, ... }: {
  age.secrets.powerdnsConfig.file = ../../secrets/${name}/powerdnsConfig.age;
  security.acme.certs."ns2.owo.systems" = {
    postRun = let
      homeDir = config.services.mysql.dataDir;
      sqlUser = config.services.mysql.dataDir;
      sqlGroup = config.services.mysql.dataDir;
      sqlPackage = config.services.mysql.package;
    in ''
      cp fullchain.pem "${homeDir}/"
      cp key.pem "${homeDir}/"
      chown ${sqlUser}:${sqlGroup} "${homeDir}/fullchain.pem"
      chown ${sqlUser}:${sqlGroup} "${homeDir}/key.pem"
      # Reload Mariadb
      ${sqlPackage}/bin/mysql -Bse 'FLUSH SSL;'
    '';
  };
  services = {
    mysqlBackup = {
      enable = true;
      # Backup daily
      calendar = "*-*-* 00:00:00";
      singleTransaction = true;
      databases = [ "powerdns" ];
    };
    mysql = {
      package = pkgs.mariadb;
      enable = true;
      settings = let cfg = config.services.mysql;
      in {
        mysqld = {
          server_id = 2;
          bind_address = "0.0.0.0";
          log_bin = true;
          log_basename = "mysql_1";
          binlog_format = "mixed";
          skip_name_resolve = true;
          max_connect_errors = 4294967295;
        };
        mariadb = {
          ssl_cert = "${cfg.dataDir}/fullchain.pem";
          ssl_key = "${cfg.dataDir}/key.pem";
          ssl_ca = "/etc/ssl/certs/ca-bundle.crt";
        };
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

        gmysql-port=3366
        gmysql-host=127.0.0.1
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
