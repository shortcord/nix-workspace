{ config, pkgs, ... }: {
  users.groups."torrents" = {};
  imports = [ ./qbittorrent.nix ./sonarr.nix ./radarr.nix ./jackett.nix ./bazarr.nix ./lidarr.nix ];
}
