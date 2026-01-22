let
  ## Import the flake one dir above to get lib
  flake = builtins.getFlake (toString ../.);
  lib = flake.inputs.nixpkgs.lib;

  ## this config is a bit more than just a set, we doin' funny magic here
  scConfig = import ../config/default.nix { inherit lib; };

  mkHostSecrets = fqdn: names:
    lib.genAttrs
      (map (n: "${fqdn}/${n}.age") names)
      (_: { publicKeys = scConfig.keyForHost fqdn; });
in
{
  # General Secrets
  "general/distributedUserSSHKey.age".publicKeys = scConfig.sshkeys.allHosts;
  "general/pdnsApiKey.age".publicKeys = scConfig.sshkeys.allHosts;
  "general/promtailPassword.age".publicKeys = scConfig.sshkeys.allHosts;
  "general/acmeCredentialsFile.age".publicKeys = scConfig.sshkeys.allHosts;
  "general/restic-password.age".publicKeys = scConfig.sshkeys.allHosts;
  "general/restic-s3-env.age".publicKeys = scConfig.sshkeys.allHosts;
  "general/headscaleKey.age".publicKeys = scConfig.sshkeys.allHosts;
  "general/pia.age".publicKeys = scConfig.sshkeys.allHosts;
}
  // mkHostSecrets "ns2.owo.systems" [
    "wireguardPrivateKey"
    "wireguardPresharedKey"
    "powerdnsConfig"
    "mysqldExporterConfig"
    "invoiceplane-dbpwd"
  ]
  // mkHostSecrets "storage.owo.systems" [
    "minioSecret"
    "acmeCredentialsFile"
    "wireguardPrivateKey"
    "wireguardPresharedKey"
   ]
  // mkHostSecrets "violet.lab.shortcord.com" [
    "nix-serve"
    "calckey-config"
    "minioSecret"
    "wingsToken"
    "gallery-dl-config"
    "wg0-private-key"
    "acmeCredentialsFile"
    "minioPrometheusBearerToken"
    "mysqldExporterConfig"
    "deluged"
  ]
  // mkHostSecrets "vm-01.hetzner.owo.systems" [
    "prometheusBasicAuthPassword"
    "powerdnsConfig"
    "wireguardPrivateKey"
    "powerdns-env"
    "blackbox"
    "minioPrometheusBearerToken"
    "lokiConfig"
    "lokiBasicAuth"
    "mysqldExporterConfig"
    "nextcloudDbPass"
    "nextcloudAdminPass"
    "nextcloudS3Secret"
    "netboxSecretKey"
    "wingsToken"
    "searxng"
  ]
  // mkHostSecrets "lilac.lab.shortcord.com" [
    "catstodon.env"
    "wireguardPrivateKey"
   ]
  // mkHostSecrets "keycloak.owo.solutions" [
    "keycloak-psql-password"
    "wireguard-mailrelay-key"
  ]
  // mkHostSecrets "lavender.lab.shortcord.com" [
    "minioSecret"
  ]