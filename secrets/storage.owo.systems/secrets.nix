let
  user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl";
  server =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7tbNsAdbSQXOTNpGKKN3mCSIUGn+hhaAqPzA7gh/Hj";
in { 
  "minioSecret.age".publicKeys = [ user server ];
  "acmeCredentialsFile.age".publicKeys = [ user server ];
  "wireguardPrivateKey.age".publicKeys = [ user server ];
  "wireguardPresharedKey.age".publicKeys = [ user server ];
 }
