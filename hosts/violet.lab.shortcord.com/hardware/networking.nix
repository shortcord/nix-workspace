{ name, pkgs, lib, config, secretPath, ... }: {
  age.secrets = {
    wg0-private-key = {
      file = secretPath name "wg0-private-key.age";
      owner = "systemd-network";
      group = "systemd-network";
    };
  };
  systemd = {
    network = {
      wait-online.anyInterface = true;
      enable = true;
      netdevs = {
        wg0 = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            Description = "Tunnel to Rack02";
          };
          wireguardConfig = {
            ListenPort = "auto";
            PrivateKeyFile = config.age.secrets.wg0-private-key.path;
            RouteTable = "off";
          };
          wireguardPeers = [
            {
              PublicKey = "a/kBn642nCzwQDCsPgI19hf15yqpZvSwqXnQDjGpQ14=";
              Endpoint = "gateway.rack02.shortcord.com:51820";
              AllowedIPs = [ "10.76.0.1/31" "0.0.0.0/0" ];
              PersistentKeepalive = 5;
            }
          ];
        };
        vmbr0 = {
          netdevConfig = {
            Kind = "bridge";
            Name = "vmbr0";
          };
        };
      };
      networks = {
        "wg0" = {
          matchConfig.Name = "wg0";
          networkConfig = {
            Address = "10.76.0.2/31";
          };
          routes = [
            { 
              Scope = "link";
              Destination = "10.76.0.1";
            }
            {
              Destination = "10.70.0.0/24";
              Gateway = "10.76.0.1";
            }
          ];
        };
        "10-wan" = {
          matchConfig.MACAddress = "98:B7:85:20:05:8A";
          networkConfig = {
            DHCP = "ipv4";
            DNS = "127.0.0.1";
            IPv6AcceptRA = false;
          };
          dhcpV4Config = {
            RouteMetric = 2048;
            Anonymize = false;
            UseDomains = false;
            UseDNS = false;
          };
          ipv6AcceptRAConfig = { RouteMetric = 2048; };
          routes = [
            {
              Gateway = "_dhcp4";
              InitialCongestionWindow = 100;
              InitialAdvertisedReceiveWindow = 100;
            }
          ];
        };
        "11-wan2" = {
          matchConfig.MACAddress = "c8:1f:66:e6:7a:51";
          linkConfig.RequiredForOnline = "no";
          networkConfig = {
            DHCP = "ipv4";
            DNS = "127.0.0.1";
            IPv6AcceptRA = true;
          };
          dhcpV4Config = {
            RouteMetric = 1024;
            Anonymize = false;
            UseDomains = false;
            UseDNS = false;
          };
          ipv6AcceptRAConfig = { RouteMetric = 1024; };
          routes = [
            {
              Gateway = "_dhcp4";
              InitialCongestionWindow = 100;
              InitialAdvertisedReceiveWindow = 100;
            }
          ];
        };
        "20-lan" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:52";
          linkConfig.RequiredForOnline = "no";
          address = [ "10.18.0.1/24" ];
          networkConfig = { 
            DHCPServer = true;
            IPMasquerade = "ipv4";
            IPv4Forwarding = true;
          };
          dhcpServerConfig = {
            ServerAddress = "10.18.0.1/24";
            DNS = "10.18.0.1";
            EmitDNS = true;
          };
        };
        "99-idrac" = {
          matchConfig.MACAddress = "5C:F9:DD:fA:4B:5D";
          linkConfig.RequiredForOnline = "no";
          networkConfig = {
            DHCP = "yes";
            DNS = "no";
            IPv6AcceptRA = false;
          };
        };
        "30-storage" = {
          matchConfig.MACAddress = "0C:42:A1:0B:C1:AE";
          linkConfig = {
            RequiredForOnline = "no";
            MTUBytes = 9200;
          };
          address = [ "10.66.0.1/30" ];
          networkConfig = {
            DHCP = "no";
            DNS = "no";
            IPv6AcceptRA = false;
          };
        };
        "31-storage" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:53";
          linkConfig.RequiredForOnline = "no";
          address = [ "10.65.0.1/30" ];
          networkConfig = {
            DHCP = "no";
            DNS = "no";
            IPv6AcceptRA = false;
          };
        };
        "vmbr0" = {
          matchConfig.Name = "vmbr0";
          linkConfig = {
            RequiredForOnline = "no";
            MTUBytes = 9400;
          };
          networkConfig = {
            DHCP = "no";
            DNS = "no";
            Address = [ "fd6f:357c:c101::1/48" ];
            IPv6AcceptRA = false;
          };
        };
      };
    };
  };
  networking = {
    hostId = "7f09cf4e";
    useDHCP = false;
    dhcpcd.enable = false;
    useNetworkd = true;
    nameservers = [
      "127.0.0.1"
    ];
    firewall = {
      enable = false;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
      interfaces.
      trustedInterfaces = [ 
        "vmbr0"
        config.services.tailscale.interfaceName
        "eno2"
        "eno3"
        "eno4"
        "enp6s0f0np0"
        "enp6s0f1np1"
      ];
    };
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "enp68s0";
      internalInterfaces = [ "eno2" ];
    };
  };
}
