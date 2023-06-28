{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    colmena.url = "github:zhaofengli/colmena/v0.3.2";
    ragenix.url = "github:yaxitech/ragenix";
  };

  outputs = { nixpkgs, colmena, ragenix, ... }:
    let
      sshkeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
      ];
    in {
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
          users.users.short = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh = { authorizedKeys.keys = sshkeys; };
          };
        };

        "storage.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file = ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "ns2.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file = ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "vm-01.hetzner.owo.systems" = { name, nodes, pkgs, lib, config, ... }: {
          age.secrets.distributedUserSSHKey.file = ./secrets/general/distributedUserSSHKey.age;
          imports = [ ./hosts/${name}.nix ];
        };

        "violet.lab.shortcord.com" = { name, nodes, pkgs, lib, config, ... }: {
          imports = [ ./hosts/${name}.nix ];
        };
      };
    };
}
