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

    # This key exists on the proxmox hypervisor, a deployment
    # script will bind-mount it into the container so that
    # the container can decrypt general secrets on first boot. 
    age.identityPaths = lib.mkAfter [
        "/agenix/shared-container-key"
    ];
}
