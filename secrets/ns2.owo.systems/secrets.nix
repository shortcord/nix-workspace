let
  user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl";
  server =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ82K8WXoxEZMyU2VolrWvLZMVw1lR+kAvIyfMqwOxlX";
in {
  "wireguardPrivateKey.age".publicKeys = [ user server ];
  "wireguardPresharedKey.age".publicKeys = [ user server ];
}
