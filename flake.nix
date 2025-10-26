{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.05";
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

      scConfig = import ./config/default.nix;
      unstablePkgs = import nixpkgs-unstable {
        system = "x86_64-linux";
        overlays = overlays;
      };
      colmenaConfiguration = {
        meta = {
          allowApplyAll = false;
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = overlays;
            config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
              "open-webui"
            ];
          };
          # Per node override of nixpkgs
          ## "hostname" = { nixpkgs import stanza }
          ## see above for example of said stanza
          nodeNixpkgs = { };
          specialArgs = {
            inherit ragenix pterodactyl-wings nixos-mailserver nixpkgs-unstable
              shortcord-site unstablePkgs maustodon-flake;
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
              substituters = [ "https://cache.nixos.org" ];
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
          ];
        };

        "storage.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "storage" ];
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

        "lavender.lab.shortcord.com" =
          { name, nodes, pkgs, lib, config, ... }: {
            deployment.tags = [ "infra" "lab" "lavender" ];
            imports = [ ./hosts/${name}.nix ];
          };

        "lilac.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "mastodon" "lilac" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "violet.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "violet" ];
          deployment.targetHost = "violet.short.ts.shortcord.com";
          imports = [ ./hosts/${name}.nix ];
        };

        "gitlab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "container" "gitlab" ];
          deployment.targetHost = "2a01:4f8:c012:a734::10";
          imports = [ ./containers/${name}.nix ];
        };

        "keycloak.owo.solutions" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "keycloak" "auth" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "gateway.home.shortcord.com" =
          { name, nodes, pkgs, lib, config, ... }: {
          deployment = {
            tags = [ "lab" ];
            targetHost = "gateway.short.ts.shortcord.com";
          };
          imports = [ ./hosts/${name}.nix ];
        };

        "mousetail.dev" = { name, nodes, pkgs, lib, config, ... }: {
          deployment = {
            tags = [ "infra" "mousetail" ];
            targetHost = "mousetail.short.ts.shortcord.com";
          };
          imports = [ ./hosts/${name}.nix ];
        };
      };

      nixosConfigurations = lib.pipe colmenaConfiguration [
        colmena.lib.makeHive
        (builtins.getAttr "nodes")
        builtins.attrValues
        (builtins.map (node: {
          name = node.config.networking.hostName;
          value = node;
        }))
      ];

      vmPackages = lib.pipe nixosConfigurations [
        (builtins.filter (obj: !obj.value.config.boot.isContainer))
        (builtins.map (node: {
          name = "${node.value.config.networking.hostName}";
          value = node.value.config.formats.raw-efi;
        }))
        builtins.listToAttrs
      ];
    in {
      colmena = colmenaConfiguration;
      nixosConfigurations = builtins.listToAttrs nixosConfigurations;
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
    (system: { packages.vm = vmPackages; });
}
