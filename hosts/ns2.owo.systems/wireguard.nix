{ name, nodes, pkgs, lib, config, ... }: {
  age.secrets = {
    wireguardPrivateKey.file = ../../secrets/${name}/wireguardPrivateKey.age;
    wireguardPresharedKey.file = ../../secrets/${name}/wireguardPresharedKey.age;
  };
  networking = {
    firewall = {
      allowedUDPPorts = [ 51820 ];
      trustedInterfaces = [ "wg1" ];
    };
    wireguard = {
      enable = true;
      interfaces = {
        wg1 = {
          ips = [ "10.7.210.1/32" ];
          listenPort = 51820;
          privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
          peers = [
            {
              publicKey = "x8o7GM5Fk1EYZK9Mgx4/DIt7DxAygvKg310G6+VHhUs=";
              persistentKeepalive = 15;
              allowedIPs = [ "10.7.210.2/32" ];
            }
            {
              publicKey = "iCm6s21gpwlvaVoBYw0Wyaa39q/REIa+aTFXvkBFYEQ=";
              persistentKeepalive = 15;
              allowedIPs = [ "10.7.210.3/32" ];
            }
            { # keycloak.owo.gallery
              publicKey = "NHKzKkq+H+JaIdl+w6NJhn2s1UK/ewiDIhUA5KQOnxU=";
              persistentKeepalive = 15;
              allowedIPs = [ "10.7.210.4/32" ];
            }
          ];
        };
      };
    };
  };
}
