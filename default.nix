{ pkgs ? import <nixpkgs> { } }:
pkgs.buildEnv {
  name = "my-tools";
  paths = with pkgs; [ colmena nixos-generators vim (callPackage <agenix/pkgs/agenix.nix> { }) ];
}
