{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    colmena.url = "github:zhaofengli/colmena/v0.3.2";
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    owo-solutions-homepage = {
      url =
        "git+https://gitlab.shortcord.com/owo.solutions/homepage?ref=refs/heads/feature/nix-package&rev=c56e673cc6ab45eb59bd7e85294b0d7de6aabb86";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, colmena, ragenix, nixos-generators
    , owo-solutions-homepage, ... }:
    let
      sshkeys = {
        short = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAXRx3C0/Rjiz5mpqX/Iygkr1wOTG1fw6Am9zKpZUr1 short@dellmaus"
        ];
        deployment = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzNDt0mA8dV9l5A/1tIgLVBf6ynUjjZN0Dckvs3kRIG deployment@gitlab.shortcord.com"
        ];
      };
    in {
      packages.x86_64-linux = {
        iso = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "iso";
          modules = [ ./templates/bootiso.nix ];
          specialArgs = { sshkeys = sshkeys; };
        };
        kexec = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "kexec";
          modules = [ ./templates/kexec.nix ];
          specialArgs = { sshkeys = sshkeys; };
        };
      };
      devShell.x86_64-linux = let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        buildInputs = [
          pkgs.colmena
          pkgs.nixos-generators
          pkgs.vim
          ragenix.packages.x86_64-linux.default
        ];
      };
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ ];
          };
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
              openssh = { authorizedKeys.keys = sshkeys.deployment; };
            };
            short = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              openssh = { authorizedKeys.keys = sshkeys.short; };
            };
          };
        };

        "storage.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "ns2.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "vm-01.hetzner.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "lilac.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "violet.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file =
            ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };
        "dellmaus.lan" = { name, nodes, pkgs, lib, config, ... }: {
          imports = [ ./hosts/${name}.nix ];
        };
      };
    };
}
