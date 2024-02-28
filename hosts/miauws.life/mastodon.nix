{ name, pkgs, config, lib, ... }:
let mastConfig = config.services.mastodon;
in {
  age.secrets = {
    catstodon-env.file = ../../secrets/${name}/catstodon.env.age;
  };
  networking = {
    firewall = lib.mkIf config.networking.firewall.enable {
      allowedTCPPorts = [ 80 443 ];
    };
  };
  services = {
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedBrotliSettings = true;
      virtualHosts.${mastConfig.localDomain} = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          client_max_body_size 500M;
          # contentnation.net
          deny 2a01:4f8:140:2113::2/128;
          deny 46.4.60.46/32;
        '';
      };
    };
    mastodon = {
      enable = true;
      enableUnixSocket = false;
      localDomain = "${config.networking.fqdn}";
      configureNginx = true;
      smtp.fromAddress = "noreply@${mastConfig.localDomain}";
      extraEnvFiles = [ config.age.secrets.catstodon-env.path ];
      
      streamingProcesses = 4;
      
      extraConfig = {
        AUTHORIZED_FETCH = "true";
        DISALLOW_UNAUTHENTICATED_API_ACCESS = "false";

        MAX_TOOT_CHARS = "69420";
        MAX_DESCRIPTION_CHARS = "69420";
        MAX_BIO_CHARS = "69420";
        MAX_PROFILE_FIELDS = "10";
        MAX_PINNED_TOOTS = "10";
        MAX_DISPLAY_NAME_CHARS = "50";
        MIN_POLL_OPTIONS = "1";
        MAX_POLL_OPTIONS = "20";
        MAX_REACTIONS = "6";
        MAX_SEARCH_RESULTS = "1000";
        MAX_REMOTE_EMOJI_SIZE = "1048576";
      };
      database = {
        createLocally = true;
        host = "/run/postgresql";
      };
      package = pkgs.maustodon;
    };
    postgresqlBackup = {
      enable = true;
      compression = "zstd";
      databases = [ mastConfig.database.name "matrix_synapse" ];
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ mastConfig.database.name ];
      ensureUsers = [{
        name = mastConfig.database.user;
        ensurePermissions = {
          "DATABASE ${mastConfig.database.name}" = "ALL PRIVILEGES";
        };
      }];
    };
  };
}
