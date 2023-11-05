{ ... }: {
  imports = [
    ./dyndns-ipv4.nix
    ./dyndns-ipv6.nix
    ./promtail.nix
  ];
}
