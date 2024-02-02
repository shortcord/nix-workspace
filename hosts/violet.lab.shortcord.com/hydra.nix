{ name, pkgs, config, lib, ... }: {
  age.secrets.nix-serve.file = ../../secrets/${name}/nix-serve.age;
  nix.settings.secret-key-files = [ config.age.secrets.nix-serve.path ];
  services = {
    nginx = {
      virtualHosts = {
        "binarycache.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://${config.services.nix-serve.bindAddress}:${
                toString config.services.nix-serve.port
              }";
          };
        };
        "hydra.${config.networking.fqdn}" = lib.mkIf config.services.hydra.enable {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

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
      enable = false;
      listenHost = "localhost";
      hydraURL = "https://hydra.${config.networking.fqdn}";
      notificationSender = "hydra@${config.networking.fqdn}";
      buildMachinesFiles = [];
      useSubstitutes = false;
    };
  };
}
