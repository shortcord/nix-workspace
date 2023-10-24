{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    colmena.url = "github:zhaofengli/colmena/release-0.4.x";
    flake-utils.url = "github:numtide/flake-utils";
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pterodactyl-wings.url = "path:./pkgs/pterodactyl/wings";
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, colmena, ragenix, nixos-generators, flake-utils
    , nixos-mailserver, pterodactyl-wings, ... }:
    let scConfig = import ./config/default.nix;
    in {
      packages.x86_64-linux = {
        iso = nixos-generators.nixosGenerate {
          format = "iso";
          system = "x86_64-linux";
          modules = [ ./templates/bootiso.nix ];
          specialArgs = { scConfig = scConfig; };
        };
        proxmox-lxc = nixos-generators.nixosGenerate {
          format = "proxmox-lxc";
          system = "x86_64-linux";
          modules = [ ./templates/proxmox-lxc.nix ];
          specialArgs = { scConfig = scConfig; };
        };
        proxmox = nixos-generators.nixosGenerate {
          format = "proxmox";
          system = "x86_64-linux";
          modules = [ ./templates/proxmox.nix ];
          specialArgs = { scConfig = scConfig; };
        };
        "miauws-life" = nixos-generators.nixosGenerate {
          format = "proxmox";
          system = "x86_64-linux";
          modules = [ ./hosts/miauws.life.nix ];
          specialArgs = { scConfig = scConfig; };
        };
      };

      devShells = {
        x86_64-darwin.default = nixpkgs.legacyPackages.x86_64-darwin.mkShell {
          buildInputs = [
            nixpkgs.legacyPackages.x86_64-darwin.colmena
            nixpkgs.legacyPackages.x86_64-darwin.nixos-generators
            nixpkgs.legacyPackages.x86_64-darwin.vim
          ] ++ [ ragenix.packages.x86_64-darwin.default ];
        };
        x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
          buildInputs = [
            nixpkgs.legacyPackages.x86_64-linux.colmena
            nixpkgs.legacyPackages.x86_64-linux.nixos-generators
            nixpkgs.legacyPackages.x86_64-linux.vim
          ] ++ [ ragenix.packages.x86_64-linux.default ];
        };
      };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ pterodactyl-wings.overlays.default ];
          };
          specialArgs = { inherit ragenix pterodactyl-wings nixos-mailserver; };
        };
        defaults = {
          deployment = {
            targetUser = "short";
            buildOnTarget = true;
          };
          nix = {
            settings = {
              experimental-features = [ "nix-command" "flakes" ];
              auto-optimise-store = true;
              substituters = [ "https://binarycache.violet.lab.shortcord.com" ];
              trusted-public-keys = [
                "binarycache.violet.lab.shortcord.com:Bq1Q/51gHInHj8dMKoaCI5lHM8XnwASajahLe1KjCdQ="
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

        "miauws.life" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "miauws" ];
          imports = [ ./hosts/${name}.nix ];
        };
      };
    };
}
