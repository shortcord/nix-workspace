{ config, lib, secretPath, ... }: {
  imports = [
    ./restic.nix
  ];

  age.secrets = {
    distributedUserSSHKey.file = lib.mkForce (secretPath "general" "distributedUserSSHKey.age");
    headscaleKey.file = secretPath "general" "headscaleKey.age";
  };

  services = {
    tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.headscaleKey.path;
      extraUpFlags = [ "--login-server" "https://headscale.ns2.owo.systems" "--accept-routes" "--accept-dns" "--reset" ];
    };
  };
}
