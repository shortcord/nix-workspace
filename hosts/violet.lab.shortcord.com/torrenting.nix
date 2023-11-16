{ config, pkgs, ... }: 
{
    imports = [
        ./deluged.nix
        ./sonarr.nix
        ./radarr.nix
        ./jackett.nix
    ];
}