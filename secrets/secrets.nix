let
  scConfig = import ../config/default.nix;
  all = scConfig.sshkeys.users.short ++ scConfig.sshkeys.hosts.general;
in
{
  # General Secrets
  "general/distributedUserSSHKey.age".publicKeys = all;
  "general/pdnsApiKey.age".publicKeys = all;
  
  # Secrets for ns2.owo.systems
  "ns2.owo.systems/wireguardPrivateKey.age".publicKeys = all;
  "ns2.owo.systems/wireguardPresharedKey.age".publicKeys = all;
  "ns2.owo.systems/powerdnsConfig.age".publicKeys = all;
  
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
  "vm-01.hetzner.owo.systems/powerdnsConfig.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/wireguardPrivateKey.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/powerdns-env.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/blackbox.age".publicKeys = all;

  # Secrets for lilac.lab.shortcord.com
  "lilac.lab.shortcord.com/catstodon.env.age".publicKeys = all;
  "lilac.lab.shortcord.com/wireguardPrivateKey.age".publicKeys = all;
}