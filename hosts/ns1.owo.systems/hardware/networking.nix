{ name, pkgs, lib, config, ... }: {
  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowPing = true;
    };
    wireguard = {
      enable = true;
      interfaces = {
        "mail-relay" = {
          ips = [ "10.7.210.4/32" ];
          mtu = 1200;
          privateKeyFile = config.age.secrets.wireguard-mailrelay-key.path;
          peers = [{
            publicKey = "2a8w4y36L4hiG2ijQKZOfKTar28A4SPtupZnTXVUrTI=";
            persistentKeepalive = 15;
            allowedIPs = [ "10.7.210.1/32" ];
            endpoint = "66.135.9.121:51820";
          }];
        };
      };
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "00:50:56:09:46:34";
        networkConfig = {
          DHCP = "no";
          DNS = [ "127.0.0.1" "::1" ];
          Address = [ "147.135.125.70/32" "2604:2dc0:100:1b1e::31/64" ];
          Gateway = [ "51.81.11.254" "2604:2dc0:0100:1bff:00ff:00ff:00ff:00ff" ];
        };
        routes = [
          {
            Scope = "link";
            Destination = "51.81.11.254";
          }
          {
            Scope = "link";
            Destination = "2604:2dc0:0100:1bff:00ff:00ff:00ff:00ff";
          }
        ];
      };
    };
  };
}
