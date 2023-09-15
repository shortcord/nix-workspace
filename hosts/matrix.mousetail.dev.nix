{ name, nodes, pkgs, lib, config, ... }: {
    system.stateVersion = "23.05";

    services.httpd.enable = true;

    networking = {
        hostName = "matrix";
        domain = "mousetail.dev";
        firewall = {
        enable = true;
        allowedUDPPorts = [ ];
        allowedTCPPorts = [ 22 80 ];
        allowPing = true;
        };
    };
}