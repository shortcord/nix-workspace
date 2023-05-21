{ pkgs ? import <nixpkgs> { } }:
pkgs.buildEnv {
  name = "my-tools";
  paths = with pkgs; [ colmena vim (callPackage <agenix/pkgs/agenix.nix> { }) ];
}
