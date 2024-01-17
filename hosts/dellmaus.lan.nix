{ name, nodes, pkgs, lib, config, ... }:

{
  system.stateVersion = "22.11";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    initrd = {
      secrets = { "/crypto_keyfile.bin" = null; };
      luks = {
        devices = {
          "luks-4cd23fd1-2aae-4048-8b0c-ab3c4ccce27d" = {
            device = "/dev/disk/by-uuid/4cd23fd1-2aae-4048-8b0c-ab3c4ccce27d";
          };
          "luks-cfb641b2-60f7-4d6f-9fba-9ca2af48b76f" = {
            device = "/dev/disk/by-uuid/cfb641b2-60f7-4d6f-9fba-9ca2af48b76f";
            keyFile = "/crypto_keyfile.bin";
          };
        };
      };
      availableKernelModules =
        [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" "sdhci_pci" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/9473d2dd-5cf6-472f-8aa2-820abecb440b";
      fsType = "ext4";
    };
    "/boot/efi" = {
      device = "/dev/disk/by-uuid/9EE4-5D9B";
      fsType = "vfat";
    };
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/d64575f0-c286-4d23-905c-600521025110"; }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
  };

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services = {
    openssh = { enable = true; };
    acpid.enable = true;
    xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "";
      libinput.enable = true;
      displayManager.defaultSession = "none+i3";
      desktopManager.xterm.enable = false;
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          rofi
          xclip
          i3status
          i3lock
          betterlockscreen
          feh
          xfe
          playerctl
          alacritty
        ];
      };
    };
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    kubo = {
      enable = true;
      autoMigrate = true;
      enableGC = true;
      emptyRepo = true;
      settings = {
        Addresses = {
          API = [ "/ip4/127.0.0.1/tcp/5001" "/unix/run/ipfs.sock" ];
          Gateway = [ "/ip4/127.0.0.1/tcp/8080" ];
        };
      };
    };
  };

  # Enable zRam as Swap
  zramSwap.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  users.users.short = {
    shell = pkgs.zsh;
    extraGroups =
      [ "networkmanager" "wheel" "docker" config.services.kubo.group ];
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ vim ];
  programs = {
    zsh.enable = true;
    steam.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
    };
    tmux.enable = true;
    htop.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };
}
