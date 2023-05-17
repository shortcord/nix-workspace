{ config, pkgs, lib, ... }:

let
  sshkey = {
    desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus";
    surface = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface";
    default = [ sshkey.desktop sshkey.surface ];
};
in {
  kexec.autoReboot = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "C.UTF-8";

  users.users.root.openssh.authorizedKeys.keys = sshkey.default;

  boot.tmpOnTmpfs = true;

  programs = {
    vim.defaultEditor = true;
  };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "yes";
      passwordAuthentication = false;
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

  system.stateVersion = "22.11"; # Did you read the comment?
}
