{
  description = "Pterodactyl";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/23.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }:
    {
      nixosModules = rec
      {
        pterodactyl-wings = import ./wings/module.nix;
        default = pterodactyl-wings;
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pterodactyl-wings = pkgs.callPackage ./wings/pkgs/pterodactyl/wings/flake.nixdefault.nix {};
      in
        {
          packages =
          {
            default = pterodactyl-wings;
            pterodactyl-wings = pterodactyl-wings ;
          };
        }
      );
}
