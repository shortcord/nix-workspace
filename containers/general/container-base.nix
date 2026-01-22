{ config, lib, modulesPath, ... }: {
    imports = [
        (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ];

    proxmoxLXC = {
        enable = true;
        privileged = false;
        manageNetwork = false;
        manageHostName = false;
    };

    age.identityPaths = lib.mkAfter [
        "/agenix/shared-container-key"
    ];
}
