{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    colmena.url = "github:zhaofengli/colmena/v0.3.2";
    flake-utils.url = "github:numtide/flake-utils";
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, colmena, ragenix, nixos-generators, flake-utils, ... }:
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
        meta = { nixpkgs = import nixpkgs { system = "x86_64-linux"; }; };
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
          imports = [ ragenix.nixosModules.default ];
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
          deployment.tags = [ "infra" "nameserver" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "vm-01.hetzner.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "nameserver" "grafana" "prometheus" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "lilac.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" "mastodon" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "violet.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          deployment.tags = [ "infra" "lab" ];
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        # "dellmaus.lan" = { name, nodes, pkgs, lib, config, ... }: {
        #   imports = [ ./hosts/${name}.nix ];
        # };
      };
    };
}
