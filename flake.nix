{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    colmena.url = "github:zhaofengli/colmena/release-0.4.x";
    flake-utils.url = "github:numtide/flake-utils";
    nixfmt.url = "github:serokell/nixfmt";
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pterodactyl-wings = {
      url =
        "git+https://gitlab.shortcord.com/shortcord/pterodactyl-wings-flake?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shortcord-site = {
      url =
        "git+https://gitlab.shortcord.com/shortcord/shortcord.com.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    maustodon-flake = {
      url =
        "git+https://gitlab.shortcord.com/shortcord/maustodon-flake.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, colmena, ragenix, flake-utils
    , nixos-mailserver, pterodactyl-wings, shortcord-site, maustodon-flake
    , nixos-generators, nixfmt, ... }:
    let
      inherit (nixpkgs) lib;

      # Single source of truth for unfree packages allowed across all nixpkgs instances (stable and unstable)
      allowUnfreeList = [
        "open-webui"
        "ollama"
        "ollama-cuda"
        "mastodon"
        "nvidia-x11"
        "nvidia-persistenced"
        "nvidia-container-toolkit"
        "nvidia-settings"
        "cudatoolkit"
        "cuda_cudart"
        "cuda_nvcc"
        "cuda_cccl"
        "libcublas"
        "cuda-merged"
        "cuda_cuobjdump"
        "cuda_gdb"
        "cuda_nvdisasm"
        "cuda_nvprune"
        "cuda_cupti"
        "cuda_cuxxfilt"
        "cuda_nvml_dev"
        "cuda_nvrtc"
        "cuda_nvtx"
        "cuda_profiler_api"
        "cuda_sanitizer_api"
        "libcufft"
        "libcurand"
        "libcusolver"
        "libnvjitlink"
        "libcusparse"
        "libnpp"
        "nvidia-kernel-modules"
      ];
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowUnfreeList;

      overlays = [
        pterodactyl-wings.overlays.default
        shortcord-site.overlays.default
        maustodon-flake.overlays.default
        colmena.overlays.default
        ragenix.overlays.default
      ];

      imports = [
        ragenix.nixosModules.default
        pterodactyl-wings.nixosModules.default
        nixos-mailserver.nixosModules.default
        nixos-generators.nixosModules.all-formats
      ];

      scConfig = import ./config/default.nix { inherit lib; };
      # Helper to construct absolute secret paths — works from any file depth
      secretPath = hostName: secretFile: ./secrets/${hostName}/${secretFile};
      unstablePkgs = import nixpkgs-unstable {
        system = "x86_64-linux";
        overlays = overlays;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };
      colmenaConfiguration = {
        meta = {
          allowApplyAll = false;
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = overlays;
            config.allowUnfreePredicate = allowUnfreePredicate;
          };
          # Per node override of nixpkgs
          ## "hostname" = { nixpkgs import stanza }
          ## see above for example of said stanza
          nodeNixpkgs = { };
          specialArgs = {
            inherit ragenix pterodactyl-wings nixos-mailserver nixpkgs-unstable
              shortcord-site unstablePkgs maustodon-flake secretPath;
          };
        };
        defaults = { name, lib, config, pkgs, ... }: {
          deployment = {
            targetUser = "short";
            buildOnTarget = false;
            tags = lib.mkOrder 1000
              (lib.optional (!config.boot.isContainer) "default");
          };

          age.secrets = {
            distributedUserSSHKey.file =
              ./secrets/general/distributedUserSSHKey.age;
            pia-userpass.file = ./secrets/general/pia.age;

            # Ensure that the PDNS creds are installed if nginx is enabled
            acmeCredentialsFile = lib.mkIf config.services.nginx.enable {
              file = ./secrets/general/acmeCredentialsFile.age;
              owner = "acme";
              group = "acme";
            };
          };

          ## TODO: await for a patch to remove --update-input
          # ref: https://github.com/NixOS/nixpkgs/issues/349734
          system.autoUpgrade = {
            enable = true;
            flake =
              "git+https://gitlab.shortcord.com/shortcord/nix-workspace.git?ref=main";
            flags = [
              "--update-input"
              "nixpkgs"
              "--update-input"
              "nixpkgs-unstable"
              "--update-input"
              "maustodon-flake"
              "--no-write-lock-file"
              "-L" # print build logs
            ];
            dates = "02:00";
            randomizedDelaySec = "45min";
          };

          # nix-shell uses flake version
          environment.etc.nixpkgs.source = pkgs.path;
          nix.registry.nixpkgs.to = {
            path = pkgs.path;
            type = "path";
          };
          nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

          # Set hostname and domain to node name in flake by default
          networking.hostName =
            lib.mkDefault (builtins.head (lib.splitString "." name));
          networking.domain = lib.mkDefault (builtins.concatStringsSep "."
            (builtins.tail (lib.splitString "." name)));

          # Stupid
          systemd.network.wait-online.anyInterface = true;

          nix = {
            settings = {
              experimental-features = [ "nix-command" "flakes" ];
              auto-optimise-store = true;
              substituters = [ "https://binarycache.violet.lab.shortcord.com" "https://cache.nixos.org" ];
              trusted-public-keys = [
                "binarycache.violet.lab.shortcord.com:Bq1Q/51gHInHj8dMKoaCI5lHM8XnwASajahLe1KjCdQ="
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              ];
            };
            gc = {
              automatic = true;
              dates = "weekly";
              options = "--delete-older-than 2d";
            };
          };

          imports = imports;

          security = {
            sudo = { wheelNeedsPassword = false; };
            acme = {
              acceptTerms = true;
              defaults = {
                email = "short@shortcord.com";
                dnsProvider = lib.mkForce "pdns";
                environmentFile = config.age.secrets.acmeCredentialsFile.path;
                webroot = lib.mkForce null;
                renewInterval = "weekly";
                # Only add the resolvers if pdns-recursor is enabled and exportHosts is true, this is because lego will 
                # resolve the wrong SOA record since exportHosts includes the host it runs on, aka SOA for violet is localhost
                # which is factually wrong.
                extraLegoFlags =
                  lib.mkIf
                    (config.services.pdns-recursor.enable
                      && config.services.pdns-recursor.exportHosts)
                    [
                      "--dns.resolvers=9.9.9.9:53"
                      "--dns.resolvers=149.112.112.112:53"
                    ];
              };
            };
          };

          services = {
            openssh = {
              enable = true;
              settings.PasswordAuthentication = false;
            };
            fail2ban = { enable = true; };
          };

          users.users = {
            deployment = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              openssh = {
                authorizedKeys.keys = scConfig.sshkeys.users.deployment;
              };
            };
            short = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              openssh = { authorizedKeys.keys = scConfig.sshkeys.users.short; };
            };
          };

          environment.systemPackages = with pkgs; [
            vim
            git
            dig
            iftop
            htop
            cloud-utils
            speedtest-cli
            pciutils
            wget
            curl
            nload
            iotop
          ];
        };

        "storage.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "storage" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "ns1.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "nameserver" "ns1" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "ns2.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "nameserver" "ns2" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "vm-01.hetzner.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags =
            [ "infra" "nameserver" "grafana" "prometheus" "vm-01" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "lavender.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "lavender" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "lilac.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "mastodon" "lilac" ];
          # VM sits behind firewall, tailscale is needed for ssh deployment
          deployment.targetHost = "lilac.ts.shortcord.com";
          imports = [ ./hosts/${name}.nix ];
        };

        "violet.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "violet" ];
          deployment.targetHost = "violet.ts.shortcord.com";
          imports = [ ./hosts/${name}.nix ];
        };

        "keycloak.owo.solutions" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "keycloak" "auth" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "gitlab.rack02.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "keycloak" "auth" ];
          imports = [ ./containers/gitlab.shortcord.com.nix ];
        };
      };

      hive = colmena.lib.makeHive colmenaConfiguration;

      # Let's pull this inline fnc out instead
      safeName = n: lib.replaceStrings [ "." ] [ "-" ] n;

      vmPackages = lib.mapAttrs' (n: node:
        lib.nameValuePair (safeName n) node.config.formats.raw-efi
      ) (lib.filterAttrs (_: node: !node.config.boot.isContainer) hive.nodes);

      lxcPackages = lib.mapAttrs' (n: node:
        lib.nameValuePair (safeName n) node.config.formats.proxmox-lxc
      ) (lib.filterAttrs (_: node: node.config.boot.isContainer) hive.nodes);

    in {
      colmena = colmenaConfiguration;
      nixosConfigurations = lib.mapAttrs'(n: v: lib.nameValuePair (builtins.head (lib.splitString "." n)) v) hive.nodes;
      hydraJobs = lib.mapAttrs'
        (n: node:
          lib.nameValuePair
            (safeName n)
            node.config.system.build.toplevel
        )
        hive.nodes;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = "${system}";
          overlays = overlays;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.ragenix pkgs.colmena pkgs.nixfmt ];
        };
      }) // flake-utils.lib.eachSystem [ "x86_64-linux" ]
    (system: { 
      # flatten packages
      packages =
        (lib.mapAttrs' (n: v: lib.nameValuePair "vm-${n}" v) vmPackages)
        // (lib.mapAttrs' (n: v: lib.nameValuePair "lxc-${n}" v) lxcPackages);
    });
}
