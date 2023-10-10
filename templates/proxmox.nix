{ pkgs, modulesPath, lib, scConfig, ... }: {
  imports = [ "${modulesPath}/virtualisation/proxmox-image.nix" ];

  proxmox = {
    qemuConf = {
      boot = "order=virtio0";
      bios = "ovmf";
      agent = true;
    };
    partitionTableType = "efi";
  };

  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    tmp.useTmpfs = true;
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 4;
    };
  };

  system.stateVersion = "23.05";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    substituters = [ "https://binarycache.violet.lab.shortcord.com" ];
    trusted-public-keys = [
      "binarycache.violet.lab.shortcord.com:Bq1Q/51gHInHj8dMKoaCI5lHM8XnwASajahLe1KjCdQ="
    ];
  };

  programs = { vim.defaultEditor = true; };

  security = { sudo = { wheelNeedsPassword = false; }; };

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
    };
    openssh = {
      enable = true;
      settings = { PasswordAuthentication = false; };
    };
  };

  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "C.UTF-8";

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowPing = true;
    };
  };

  users.users = {
    short = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = scConfig.sshkeys.users.short;
    };
  };
}
