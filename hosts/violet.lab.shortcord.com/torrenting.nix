{ config, pkgs, ... }: {
  users.groups."torrents" = {};
  imports = [ 
    ./torrents/qbittorrent.nix
    ./torrents/sonarr.nix
    ./torrents/radarr.nix
    ./torrents/jackett.nix
    ./torrents/bazarr.nix
    ./torrents/lidarr.nix
  ];
}
