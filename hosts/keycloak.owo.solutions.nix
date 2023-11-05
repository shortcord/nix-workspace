{ name, nodes, pkgs, lib, config, ... }: {
  imports = [
    ./general/all.nix
    ./${name}/hardware.nix
    ./${name}/keycloak.nix
  ];
}
