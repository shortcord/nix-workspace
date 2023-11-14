{ config, pkgs, ... }: 
{
    imports = [
        ./deluged.nix
        ./sonarr.nix
        ./jackett.nix
    ];
}