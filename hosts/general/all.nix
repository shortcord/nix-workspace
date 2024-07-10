{ config, lib, ... }: {
  imports = [
    ./restic.nix
  ];

  age.secrets = {
    distributedUserSSHKey.file = lib.mkForce ../../secrets/general/distributedUserSSHKey.age;
    headscaleKey.file = ../../secrets/general/headscaleKey.age;
  };

  services = {
    tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.headscaleKey.path;
      extraUpFlags = [ "--login-server" "https://headscale.ns2.owo.systems" ];
    };
  };
}
