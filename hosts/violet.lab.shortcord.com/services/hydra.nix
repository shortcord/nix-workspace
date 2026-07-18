{ name, pkgs, config, lib, secretPath, ... }: {
  age.secrets.nix-serve.file = secretPath name "nix-serve.age";
  nix.settings.secret-key-files = [ config.age.secrets.nix-serve.path ];
  services = {
    nginx = {
      virtualHosts = {
        "binarycache.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          useACMEHost = "${config.networking.fqdn}";

          locations."/" = {
            proxyPass = "http://${config.services.nix-serve.bindAddress}:${
                toString config.services.nix-serve.port
              }";
          };
        };
        "hydra.${config.networking.fqdn}" =
          lib.mkIf config.services.hydra.enable {
            kTLS = true;
            http2 = true;
            http3 = true;
            forceSSL = true;
            useACMEHost = "${config.networking.fqdn}";

            locations."/" = {
              proxyPass = "http://${config.services.hydra.listenHost}:${
                  toString config.services.hydra.port
                }";
            };
          };
      };
    };
    nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets.nix-serve.path;
      bindAddress = "127.0.0.1";
      port = 5000;
    };
    hydra = {
      enable = true;
      listenHost = "localhost";
      port = 3454;
      hydraURL = "https://hydra.${config.networking.fqdn}";
      notificationSender = "hydra@${config.networking.fqdn}";
      buildMachinesFiles = [ ];
      useSubstitutes = true;
    };
  };
}
