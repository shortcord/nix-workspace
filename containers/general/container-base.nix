{ config, modulesPath, ... }: {
    imports = [
        (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ];

    proxmoxLXC = {
        enable = true;
        privileged = false;
        manageNetwork = false;
        manageHostName = false;
    };
}
