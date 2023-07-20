{ config, pkgs, lib, sshkeys, ... }:
let
  sshkeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAXRx3C0/Rjiz5mpqX/Iygkr1wOTG1fw6Am9zKpZUr1 short@dellmaus"
  ];
in {
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
    wireguard.enable = false;
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowPing = true;
    };
    tempAddresses = "disabled";
  };

  users.users = {
    root = {
      password = "root";
      openssh.authorizedKeys.keys = sshkeys.short;
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
}
