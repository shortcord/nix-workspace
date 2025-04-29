{ name, pkgs, lib, config, ... }: {
  users.groups."torrents" = {};
  imports = [
    ./qbittorrent.nix
    ./bazarr.nix
    ./lidarr.nix
    ./radarr.nix
    ./sonarr.nix
  ];
}
