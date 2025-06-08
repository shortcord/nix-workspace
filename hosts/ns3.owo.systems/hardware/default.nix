{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-guest-agent.nix")
    ./hardware.nix
  ];

  services.qemuGuest.enable = true;
}