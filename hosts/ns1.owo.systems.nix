{ name, nodes, pkgs, lib, config, ... }: {
  imports = [
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
}
