{ name, nodes, pkgs, lib, config, ... }: {
  imports = [
    ./general/all.nix
    ./${name}/hardware.nix
    ./${name}/wireguard.nix
    ./${name}/nginx.nix
    ./${name}/postfix.nix
    ./${name}/powerdns.nix
    ./${name}/headscale.nix
  ];

  age.secrets.mysqldExporterConfig = {
    file = ../secrets/${name}/mysqldExporterConfig.age;
    owner = "prometheus";
    group = "prometheus";
  };

  services = {
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
}