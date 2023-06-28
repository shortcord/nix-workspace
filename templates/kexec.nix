{ config, pkgs, lib, sshkeys, ... }: {
  system.stateVersion = "23.05"; # Did you read the comment?
  boot = {
    # pin kernel to 6.1 lts
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    kernelParams = [ "console=tty0" ];
    supportedFilesystems = lib.mkForce [ "btrfs" "vfat" "xfs" ];
    tmp.useTmpfs = true;
  };

  kexec.autoReboot = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
      openssh.authorizedKeys.keys = sshkeys;
    };
  };

  environment.systemPackages = with pkgs;
    [
      # system tooling
      psutils
      pstree
      file
      # shell tooling
      bvi
      jq
      moreutils
      pv
      tree
      # tui tooling
      tmux
      # debugging
      curl
      dig
      htop
      iftop
      netcat-openbsd
      tcpdump
      # filesystem tooling
      btrfs-progs
      cryptsetup
      dosfstools
    ] ++ [
      # system tooling
      efibootmgr
      # filesystem tooling
      mdadm
    ];

  networking = {
    firewall.enable = false;
    wireguard.enable = false;
    tempAddresses = "disabled";
    useDHCP = true;
  };
}
