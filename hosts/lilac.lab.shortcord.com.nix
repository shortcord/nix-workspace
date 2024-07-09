{ name, nodes, pkgs, lib, config, modulesPath, ... }:
let
  distributedUserSSHKeyPub = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnmaQeov9+Xv7z/ulQ0zPVDN3ZKW4AUK8IyoVkbUKQa"
  ];
in {
  age.secrets = {
    wireguardPrivateKey = {
      file = ../secrets/${name}/wireguardPrivateKey.age;
      owner = "systemd-network";
      group = "systemd-network";
    };
  };

  system.stateVersion = "23.05";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./general/all.nix
    ./general/dyndns-ipv6.nix
    ./${name}/hardware.nix
    ./${name}/mastodon.nix
    # ./${name}/matrix.nix
    ./${name}/postgresql.nix
  ];

  networking = {
    useDHCP = false;
    nameservers = [ "10.18.0.1" ];
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
    };
    wireguard = {
      enable = true;
      interfaces = {
        "wg0" = {
          ips = [ "10.6.210.29/32" ];
          mtu = 1200;
          listenPort = 51820;
          privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
          peers = [{
            publicKey = "ePYkBTYZaul66VdGLG70IZcCvIaZ7aSeRrkb+hskhiQ=";
            endpoint = "router.cloud.shortcord.com:51820";
            persistentKeepalive = 15;
            allowedIPs = [ "10.6.210.1/32" "10.6.210.0/24" "0.0.0.0/0" ];
          }];
        };
        "mail-relay" = {
          ips = [ "10.7.210.3/32" ];
          mtu = 1200;
          privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
          peers = [{
            publicKey = "2a8w4y36L4hiG2ijQKZOfKTar28A4SPtupZnTXVUrTI=";
            persistentKeepalive = 15;
            allowedIPs = [ "10.7.210.1/32" ];
            endpoint = "ns2.owo.systems:51820";
          }];
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ vim wget curl ];

  users.users.remotebuild = {
    isNormalUser = true;
    openssh = { authorizedKeys.keys = distributedUserSSHKeyPub; };
  };

  services = {
    qemuGuest.enable = true;
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = true;
        };
      };
    };
  };
}
