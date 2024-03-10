{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    colmena.url = "github:zhaofengli/colmena/release-0.4.x";
    flake-utils.url = "github:numtide/flake-utils";
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
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shortcord-site = {
      url =
        "git+https://gitlab.shortcord.com/shortcord/shortcord.com.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catstdon-flake = {
      url =
        "git+https://gitlab.shortcord.com/shortcord/maustodon-flake.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, colmena, ragenix, flake-utils
    , nixos-mailserver, pterodactyl-wings, shortcord-site, catstdon-flake, ...
    }:
    let
      inherit (nixpkgs) lib;
      scConfig = import ./config/default.nix;
      colmenaConfiguration = {
        meta = {
          allowApplyAll = false;
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              pterodactyl-wings.overlays.default
              shortcord-site.overlays.default
              catstdon-flake.overlays.default
            ];
          };
          # Per node override of nixpkgs
          ## "hostname" = { nixpkgs import stansa }
          ## see above for example of said stansa
          nodeNixpkgs = { };
          specialArgs = {
            inherit ragenix pterodactyl-wings nixos-mailserver nixpkgs-unstable
              shortcord-site catstdon-flake;
          };
        };
        defaults = { name, lib, config, pkgs, ... }: {
          deployment = {
            targetUser = "short";
            buildOnTarget = true;
            tags = lib.mkOrder 1000
              (lib.optional (!config.boot.isContainer) "default");
          };

          # nix-shell uses flake version
          environment.etc.nixpkgs.source = pkgs.path;
          nix.registry.nixpkgs.to = { path = pkgs.path; type = "path"; };
          nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

          # Set hostname and domain to node name in flake by default
          networking.hostName =
            lib.mkDefault (builtins.head (lib.splitString "." name));
          networking.domain = lib.mkDefault (builtins.concatStringsSep "."
            (builtins.tail (lib.splitString "." name)));

          nix = {
            settings = {
              experimental-features = [ "nix-command" "flakes" ];
              auto-optimise-store = true;
              substituters = [
                "https://cache.nixos.org"
              ];
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

          imports = [
            ragenix.nixosModules.default
            pterodactyl-wings.nixosModules.default
            nixos-mailserver.nixosModules.default
          ];

          security = {
            sudo = { wheelNeedsPassword = false; };
            acme = {
              acceptTerms = true;
              defaults.email = "short@shortcord.com";
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

          age.secrets = {
            distributedUserSSHKey.file =
              ./secrets/general/distributedUserSSHKey.age;
          };

          environment.systemPackages = with pkgs; [
            vim
            git
            dig
            iftop
            htop
            cloud-utils
          ];
        };

        "hydra.owo.solutions" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "hydra" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "storage.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "storage" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "ns2.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "nameserver" "ns2" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "vm-01.hetzner.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags =
            [ "infra" "nameserver" "grafana" "prometheus" "vm-01" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "gateway.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "gateway" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "lilac.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "mastodon" "lilac" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "violet.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "violet" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        # Awaiting Migration
        # "gitlab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
        #   deployment.tags = [ "infra" "container" "gitlab" ];
        #   deployment.targetHost = "2a01:4f8:c012:a734::10";
        #   imports = [ ./containers/${name}.nix ];
        # };

        "miauws.life" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "miauws" ];
          imports = [ ./hosts/${name}.nix ];
        };

        "keycloak.owo.solutions" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "keycloak" "auth" ];
          imports = [ ./hosts/${name}.nix ];
        };
      };
    in {
      devShells = {
        x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
          buildInputs = [
            nixpkgs.legacyPackages.x86_64-linux.colmena
            nixpkgs.legacyPackages.x86_64-linux.vim
          ] ++ [ ragenix.packages.x86_64-linux.default ];
        };
      };

      colmena = colmenaConfiguration;

      nixosConfigurations = lib.pipe colmenaConfiguration [
        colmena.lib.makeHive
        (builtins.getAttr "nodes")
        builtins.attrValues
        (builtins.map (node: {
          name = node.config.networking.hostName;
          value = node;
        }))
        builtins.listToAttrs
      ];
    };
}
