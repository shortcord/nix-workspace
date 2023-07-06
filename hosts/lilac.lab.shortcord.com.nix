{ name, nodes, pkgs, lib, config, ... }:
let
  distributedUserSSHKeyPub = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnmaQeov9+Xv7z/ulQ0zPVDN3ZKW4AUK8IyoVkbUKQa"
  ];
in {
  age.secrets = {
    pdnsApiKey.file = ../secrets/general/pdnsApiKey.age;
    catstodon-env.file = ../secrets/${name}/catstodon.env.age;
    wireguardPrivateKey.file = ../secrets/${name}/wireguardPrivateKey.age;
  };

  system.stateVersion = "23.05";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/c9446e1f-2bec-49e8-a628-a32718ecfa89";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/3AC0-0F92";
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
    extraModulePackages = [ ];
    kernelParams = [ "kvm-intel" ];
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 50;
    };
    initrd = {
      availableKernelModules = [
        "ehci_pci"
        "ahci"
        "megaraid_sas"
        "usb_storage"
        "usbhid"
        "uas"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
  };

  networking = {
    hostName = "lilac";
    domain = "lab.shortcord.com";
    useDHCP = true;
    nameservers = [ "9.9.9.9" "2620:fe::fe" ];
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
    };
    wireguard = {
      enable = true;
      interfaces.wg0 = {
        ips = [ "10.6.210.29/32" ];
        mtu = 1200;
        listenPort = 51820;
        privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
        peers = [{
          publicKey = "ePYkBTYZaul66VdGLG70IZcCvIaZ7aSeRrkb+hskhiQ=";
          endpoint = "router.cloud.shortcord.com:51820";
          persistentKeepalive = 15;
          allowedIPs = [
            "10.6.210.1/32"
            "10.6.210.0/24"
            "0.0.0.0/0"
          ];
        }];
      };
    };
  };

  environment.systemPackages = with pkgs; [ vim wget curl ];

  users.users.remotebuild = {
    isNormalUser = true;
    openssh = { authorizedKeys.keys = distributedUserSSHKeyPub; };
  };

  services = {
    mastodon = {
      enable = true;
      localDomain = "social.${config.networking.fqdn}";
      configureNginx = true;
      smtp.fromAddress = "noreply@${config.services.mastodon.localDomain}";
      extraEnvFiles = [ config.age.secrets.catstodon-env.path ];
      extraConfig = {
        MAX_TOOT_CHARS = "69420";
        MAX_DESCRIPTION_CHARS = "69420";
        MAX_BIO_CHARS = "69420";
        MAX_PROFILE_FIELDS = "10";
        MAX_PINNED_TOOTS = "10";
        MAX_DISPLAY_NAME_CHARS = "50";
        MIN_POLL_OPTIONS = "1";
        MAX_POLL_OPTIONS = "20";
        MAX_REACTIONS = "6";
        MAX_SEARCH_RESULTS = "1000";
        MAX_REMOTE_EMOJI_SIZE = "1048576";
      };
      package = (pkgs.mastodon.override {
        version = "catstodon-2bcce397a9c79102233f5a7e1ddbce8920c3377c";
        srcOverride = pkgs.fetchgit {
          url = "https://github.com/CatCatNya/catstodon.git";
          rev = "2bcce397a9c79102233f5a7e1ddbce8920c3377c";
          hash = "sha256-22WPKdLvyb/KiFVhlo9KlqZy19Yd29dfNFs5lXbFJUg=";
        };
        dependenciesDir = ../pkgs/catstodon/.;
      }).overrideAttrs (self: super: {
        mastodonModules = super.mastodonModules.overrideAttrs (a: b: {
          yarnOfflineCache = pkgs.fetchYarnDeps {
            yarnLock = self.src + "/yarn.lock";
            sha256 = "sha256-abC8sRBdntqdcaLRYrLeHHczzcR/RdGguy+BOgnVqbo=";
          };
        });
      });
    };
    postgresqlBackup = {
      enable = true;
      compression = "zstd";
    }
  };

  systemd = {
    timers = {
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
      "update-dyndns-ipv6" = {
        script = ''
          set -eu
          source ${config.age.secrets.pdnsApiKey.path}
          ${pkgs.curl}/bin/curl https://''${API_USERNAME}:''${API_PASSWORD}@pdns.ingress.k8s.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl https://ipv4.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
