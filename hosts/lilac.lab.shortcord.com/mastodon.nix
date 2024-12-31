{ name, pkgs, config, ... }: {
  age.secrets = {
    catstodon-env.file = ../../secrets/${name}/catstodon.env.age;
  };
  services = {
    nginx = {
      virtualHosts.${config.services.mastodon.localDomain} = {
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
    opensearch = { enable = true; };
    mastodon = {
      enable = true;
      enableUnixSocket = false;
      localDomain = "social.${config.networking.fqdn}";
      configureNginx = true;
      smtp.fromAddress = "noreply@${config.services.mastodon.localDomain}";
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

        # Text Searching via OpenSearch
        ES_ENABLED = "true";
        ES_HOST = "127.0.0.1";
        ES_PORT = "9200";
        ES_PRESET = "single_node_cluster";

        ## Email stuff
        SMTP_SERVER = "10.7.210.1";
        SMTP_PORT = "25";
        SMTP_FROM_ADDRESS = "noreply@shortcord.com";
        SMTP_DOMAIN = "lilac.lab.shortcord.com";
      };
      database = {
        createLocally = true;
        host = "/run/postgresql";
      };
      package = pkgs.catstodon;
    };
  };
}
