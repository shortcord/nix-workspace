{
  description = "Pterodactyl Wings";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/23.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }:
    {
      nixosModules = rec
      {
        pterodactyl-wings = import ./wings/module.nix;
        default = pterodactyl-wings;
      };
      overlays.default = _final: prev: rec {
        pterodactyl-wings = self.packages.${prev.stdenv.hostPlatform.system}.pterodactyl-wings;
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pterodactyl-wings = pkgs.callPackage ./wings/default.nix {};
      in
        {
          packages = {
            default = pterodactyl-wings;
            pterodactyl-wings = pterodactyl-wings;
          };
        }
      );
}
