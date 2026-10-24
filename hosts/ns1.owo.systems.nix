{ name, nodes, pkgs, lib, config, ... }: {
  imports = [
    ./general/all.nix
    ./${name}/hardware/default.nix
  ];

  services = {
    tailscale = { useRoutingFeatures = "both"; };
    prometheus = {
      enable = true;
      exporters = {
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
