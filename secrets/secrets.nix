let
  scConfig = import ../config/default.nix;
  all = scConfig.sshkeys.users.short ++ scConfig.sshkeys.hosts.general;
in
{
  # General Secrets
  "general/distributedUserSSHKey.age".publicKeys = all;
  "general/pdnsApiKey.age".publicKeys = all;
  "general/promtailPassword.age".publicKeys = all;
  "general/acmeCredentialsFile.age".publicKeys = all;
  "general/restic-password.age".publicKeys = all;
  "general/restic-s3-env.age".publicKeys = all;
  
  # Secrets for ns2.owo.systems
  "ns2.owo.systems/wireguardPrivateKey.age".publicKeys = all;
  "ns2.owo.systems/wireguardPresharedKey.age".publicKeys = all;
  "ns2.owo.systems/powerdnsConfig.age".publicKeys = all;
  "ns2.owo.systems/mysqldExporterConfig.age".publicKeys = all;
  
  # Secrets for storage.owo.systems
  "storage.owo.systems/minioSecret.age".publicKeys = all;
  "storage.owo.systems/acmeCredentialsFile.age".publicKeys = all;
  "storage.owo.systems/wireguardPrivateKey.age".publicKeys = all;
  "storage.owo.systems/wireguardPresharedKey.age".publicKeys = all;
  
  # Secrets for violet.lab.shortcord.com
  "violet.lab.shortcord.com/nix-serve.age".publicKeys = all;
  "violet.lab.shortcord.com/calckey-config.age".publicKeys = all;
  "violet.lab.shortcord.com/minioSecret.age".publicKeys = all;
  "violet.lab.shortcord.com/wingsToken.age".publicKeys = all;
  "violet.lab.shortcord.com/gallery-dl-config.age".publicKeys = all;

  # Secrets for vm-01.hetzner.owo.systems
  "vm-01.hetzner.owo.systems/prometheusBasicAuthPassword.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/powerdnsConfig.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/wireguardPrivateKey.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/powerdns-env.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/blackbox.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/minioPrometheusBearerToken.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/lokiConfig.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/lokiBasicAuth.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/mysqldExporterConfig.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/nextcloudDbPass.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/nextcloudAdminPass.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/nextcloudS3Secret.age".publicKeys = all;
  "vm-01.hetzner.owo.systems/netboxSecretKey.age".publicKeys = all;

  # Secrets for lilac.lab.shortcord.com
  "lilac.lab.shortcord.com/catstodon.env.age".publicKeys = all;
  "lilac.lab.shortcord.com/wireguardPrivateKey.age".publicKeys = all;

  # Secrets for miauws.life
  "miauws.life/catstodon.env.age".publicKeys = all;
  "miauws.life/email-short.env.age".publicKeys = all;
  "miauws.life/email-noreply.env.age".publicKeys = all;

  # Secrets for keycloak.owo.solutionss
  "keycloak.owo.solutions/keycloak-psql-password.age".publicKeys = all;
  "keycloak.owo.solutions/wireguard-mailrelay-key.age".publicKeys = all;
}