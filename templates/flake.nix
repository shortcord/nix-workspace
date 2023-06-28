{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      sshkeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
      ];
    in {
      packages.x86_64-linux = {
        iso = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "iso";
          modules = [ ./bootiso.nix ];
          specialArgs = { sshkeys = sshkeys; };
        };
        kexec = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "kexec-bundle";
          modules = [ ./kexec.nix ];
          specialArgs = { sshkeys = sshkeys; };
        };
      };
    };
}
