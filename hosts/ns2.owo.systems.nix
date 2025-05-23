{ name, nodes, pkgs, lib, config, ... }: {
  imports = [
    ./general/all.nix
    ./${name}/hardware.nix
    ./${name}/wireguard.nix
    ./${name}/nginx.nix
    ./${name}/postfix.nix
    ./${name}/powerdns.nix
    ./${name}/headscale.nix
    ./${name}/jellyfin.nix
    ./${name}/invoiceplane.nix
  ];

  age.secrets = {
    mysqldExporterConfig = {
      file = ../secrets/${name}/mysqldExporterConfig.age;
      owner = "prometheus";
      group = "prometheus";
    };
    acmeCredentialsFile = {
      file = ../secrets/general/acmeCredentialsFile.age;
      owner = "acme";
      group = "acme";
    };
  };

  services = {
    tailscale = { useRoutingFeatures = "both"; };
    prometheus = {
      enable = true;
      exporters = {
        mysqld = {
          enable = true;
          openFirewall = true;
          configFile = config.age.secrets.mysqldExporterConfig.path;
        };
        node = {
          enable = true;
          openFirewall = true;
        };
        systemd = {
          enable = true;
          openFirewall = true;
        };
      };
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
    oci-containers = {
      backend = "docker";
      containers = {
        "maxscale" = {
          autoStart = true;
          image = "docker.io/mariadb/maxscale:latest";
          volumes = [ "maxscale-config:/var/lib/maxscale/:rw" ];
          ports = [ "3366:3366" ];
        };
      };
    };
  };
}
