{ pkgs, modulesPath, lib, scConfig, ... }: {
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  proxmoxLXC.manageHostName = true;

  boot = {
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
      openssh.authorizedKeys.keys = scConfig.sshkeys.users.short;
    };
  };
}
