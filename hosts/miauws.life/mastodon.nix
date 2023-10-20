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

        root = "${mastConfig.package}/public/";

        extraConfig = ''
          client_max_body_size 500M;
        '';

        locations = {
          "/system/".alias = "/var/lib/mastodon/public-system/";
          "/" = { tryFiles = "$uri @proxy"; };
          "@proxy" = {
            proxyPass = "http://127.0.0.1:${toString (mastConfig.webPort)}";
            proxyWebsockets = true;
          };
          "/api/v1/streaming/" = {
            proxyPass =
              "http://127.0.0.1:${toString (mastConfig.streamingPort)}/";
            proxyWebsockets = true;
          };
        };
      };
    };
    mastodon = {
      enable = true;
      enableUnixSocket = false;
      localDomain = "${config.networking.fqdn}";
      configureNginx = false;
      smtp.fromAddress = "noreply@${mastConfig.localDomain}";
      extraEnvFiles = [ config.age.secrets.catstodon-env.path ];
      extraConfig = {
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
      package = (pkgs.mastodon.override {
        version = import ./catstodon/version.nix;
        srcOverride = pkgs.callPackage ./catstodon/source.nix { };
        dependenciesDir = ./catstodon/.;
      }).overrideAttrs (self: super: {
        mastodonModules = super.mastodonModules.overrideAttrs (a: b: {
          yarnOfflineCache = pkgs.fetchYarnDeps {
            yarnLock = self.src + "/yarn.lock";
            sha256 = "sha256-8fUJ1RBQZ16R3IpA/JEcn+PO04ApQ9TkHuYKycvV8BY=";
          };
        });
      });
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
