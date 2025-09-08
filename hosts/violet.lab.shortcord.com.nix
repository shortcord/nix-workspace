{ name, nodes, pkgs, lib, config, ... }: {
  system.stateVersion = "23.05";

  imports = [
    ./general/all.nix
    ./${name}/hardware/default.nix
    ./${name}/services/default.nix
  ];

  nix = {
    buildMachines = [
      {
        hostName = "localhost";
        systems = [ "x86_64-linux" "i686-linux" ];
        supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        maxJobs = 8;
      }
    ];
    distributedBuilds = lib.mkForce false;
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config = {
      allowUnfree = true;
      ## TODO: Update these packages
      permittedInsecurePackages = [
        "dotnet-sdk-6.0.428"
        "aspnetcore-runtime-6.0.36"
        "qbittorrent-nox-4.6.4"
      ];
    };
  };

  environment.systemPackages = with pkgs; [ vim wget curl btrfs-progs git ];
  services = {
    tailscale = {
      useRoutingFeatures = "both";
      extraUpFlags = [
        "--advertise-routes"
        "10.18.0.0/24,10.200.1.0/24,fd6a:f1f3:23f4:1::/64"
        "--accept-dns=false"
      ];
    };
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/btrfs" ];
    };
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = true;
        };
      };
    };
  };

  programs = {
    dconf.enable = true;
    nix-ld.enable = true;
  };
  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
    oci-containers = {
      backend = "docker";
      containers = {
        "gitlab-runner" = {
          autoStart = true;
          image = "docker.io/gitlab/gitlab-runner:latest";
          volumes = [
            "gitlab-runner-config:/etc/gitlab-runner"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
        };
      };
    };
  };

  users.users.short = {
    extraGroups = [ "wheel" "docker" "libvirtd" config.services.kubo.group ];
  };

  systemd = {
    timers = {
      "btrfs-rebalance" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Unit = "btrfs-rebalance.service";
        };
      };
    };
    services = {
      "btrfs-rebalance" = {
        script = ''
          set -eu
          ${pkgs.btrfs-progs}/bin/btrfs balance start --full-balance /btrfs
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
