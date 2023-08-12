{ pkgs, modulesPath, lib, scConfig, ... }: {
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  boot = {
    # pin kernel to 6.1 lts
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    kernelParams = [ ];
    supportedFilesystems = lib.mkForce [ "btrfs" "vfat" "xfs" ];
    tmp.useTmpfs = true;
  };

  system.stateVersion = "23.05";

  programs = { vim.defaultEditor = true; };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkForce "yes";
        PasswordAuthentication = false;
      };
    };
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "C.UTF-8";

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowPing = true;
    };
  };

  users.users = {
    root = {
      password = "root";
      password = "password";
      openssh.authorizedKeys.keys = scConfig.sshkeys.users.short;
    };
  };
}
