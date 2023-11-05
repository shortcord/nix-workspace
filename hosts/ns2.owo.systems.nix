{ name, nodes, pkgs, lib, config, ... }: {
  imports = [
    ./general/promtail.nix
    ./general/restic.nix
    ./${name}/hardware.nix
    ./${name}/wireguard.nix
    ./${name}/nginx.nix
    ./${name}/postfix.nix
    ./${name}/powerdns.nix
  ];

  services = {
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = false;
          port = 9100;
          listenAddress = "127.0.0.1";
        };
      };
    };
  };
}
