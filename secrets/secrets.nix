let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAXRx3C0/Rjiz5mpqX/Iygkr1wOTG1fw6Am9zKpZUr1 short@dellmaus"
  ];
  servers = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKb0PHLj1RU6PPyYCZWXzVu5gXvAFSgh4SIuhMX/PJ3/ violet.lab.shortcord.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ82K8WXoxEZMyU2VolrWvLZMVw1lR+kAvIyfMqwOxlX ns2.owo.systems"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7tbNsAdbSQXOTNpGKKN3mCSIUGn+hhaAqPzA7gh/Hj storage.owo.systems"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqzy6mgAsJLPsYnYb6sWBvsmZKF8QG7lLE3A/yE55G7 vm01.hetzner.owo.systems"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4tWdXuPUVt2Yv/cGig8Hilm/NZgpsqH1VbKYpOvnwh lilac.lab.shortcord.com"
  ];
  all = users ++ servers;
in
{
  # General Secrets
  "general/distributedUserSSHKey.age".publicKeys = all;
  "general/pdnsApiKey.age".publicKeys = all;
  
  # Secrets for ns2.owo.systems
  "ns2.owo.systems/wireguardPrivateKey.age".publicKeys = all;
  "ns2.owo.systems/wireguardPresharedKey.age".publicKeys = all;
  
  # Secrets for storage.owo.systems
  "storage.owo.systems/minioSecret.age".publicKeys = all;
  "storage.owo.systems/acmeCredentialsFile.age".publicKeys = all;
  "storage.owo.systems/wireguardPrivateKey.age".publicKeys = all;
  "storage.owo.systems/wireguardPresharedKey.age".publicKeys = all;
  
  # Secrets for violet.lab.shortcord.com
  "violet.lab.shortcord.com/nix-serve.age".publicKeys = all;
  "violet.lab.shortcord.com/calckey-config.age".publicKeys = all;

  # Secrets for vm-01.hetzner.owo.systems
  "vm-01.hetzner.owo.systems/prometheusBasicAuthPassword.age".publicKeys = all;

  # Secrets for lilac.lab.shortcord.com
  "lilac.lab.shortcord.com/catstodon.env.age".publicKeys = all;
  "lilac.lab.shortcord.com/wireguardPrivateKey.age".publicKeys = all;
}
