{ pkgs, modulesPath, lib, ... }:
{
    imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

    # pin kernel to 6.1 lts
    boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    boot.supportedFilesystems = lib.mkForce [ "btrfs" "vfat" "xfs" ];

    system.stateVersion = "22.11";

    services = {
        openssh = {
            enable = true;
        };
    };

    networking = {
        firewall = {
            enable = true;
            allowedTCPPorts = [ 22 ];
            allowPing = true;
        };
    };

    users.users = {
        root = { 
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl"
            ];
        };
    };
}