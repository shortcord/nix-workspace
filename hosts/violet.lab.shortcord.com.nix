{ name, nodes, pkgs, lib, config, ... }: 
let 
  distributedUserSSHKeyPub = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnmaQeov9+Xv7z/ulQ0zPVDN3ZKW4AUK8IyoVkbUKQa" ];
in {
  age.secrets = {
    distributedUserSSHKey.file = ../secrets/general/distributedUserSSHKey.age;
    nix-serve.file = ../secrets/${name}/nix-serve.age;
  };

  system.stateVersion = "23.05";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/4b837b12-69c1-4e4e-8a97-9dd38fdba342";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2C1D-95D4";
      fsType = "vfat";
    };
  };

  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    growPartition = true;
    kernelModules = [ ];
    extraModulePackages = with config.boot.kernelPackages; [ zfs ];
    kernelParams = [ "kvm-intel" "zfs.zfs_arc_max=12884901888" ];
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 50;
    };
    initrd = {
      availableKernelModules = [
        "ehci_pci"
        "ahci"
        "megaraid_sas"
        "3w_sas"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "zfs"
      ];
      kernelModules = [ ];
    };
  };

  networking = {
    hostName = "violet";
    domain = "lab.shortcord.com";
    useDHCP = true;
    nameservers = [ "9.9.9.9" "2620:fe::fe" ];
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
    };
  };

  nix.distributedBuilds = lib.mkForce false;

  environment.systemPackages = with pkgs; [ vim wget curl zfs ];

  users.users.remotebuild = {
    isNormalUser = true;
    openssh = { authorizedKeys.keys = distributedUserSSHKeyPub; };
  };

  services = {
    zfs = {
      trim.enable = true;
      autoScrub = {
        enable = true;
        interval = "daily";
      };
    };
    nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets.nix-serve.path;
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedProxySettings = true;
      virtualHosts = {
        "binarycache.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
          };
        };
      };
    };
  };

  systemd = {
    timers = {
      "update-dyndns-ipv4" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "update-dyndns-ipv4.service";
        };
      };
      "update-dyndns-ipv6" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "update-dyndns-ipv6.service";
        };
      };
    };
    services = {
      "update-dyndns-ipv4" = {
        script = ''
          set -eu
          ${pkgs.curl}/bin/curl https://ShortCord:7m6GWrH8TtdVZLm@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv6.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
      "update-dyndns-ipv6" = {
        script = ''
          set -eu
          ${pkgs.curl}/bin/curl https://ShortCord:7m6GWrH8TtdVZLm@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv4.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
