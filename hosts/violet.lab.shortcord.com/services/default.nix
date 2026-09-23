{ name, pkgs, lib, config, ... }: {
  imports = [
    ./torrents/default.nix
    # ./gallery-dl-sync.nix
    ./pdns-recursor.nix
    ./repo-sync.nix
    ./jellyfin.nix
    ./actual.nix
    ./hydra.nix
    ./komga.nix
    ./nginx.nix
    ./ipfs.nix
    # ./wings.nix
    ./nfs.nix
    ./ollama.nix
    ./prometheus.nix
  ];
}
