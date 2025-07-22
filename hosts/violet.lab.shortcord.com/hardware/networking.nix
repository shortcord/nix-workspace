{ name, pkgs, lib, config, ... }: {
  age.secrets = {
    wg0-private-key = {
      file = ../../../secrets/${name}/wg0-private-key.age;
      owner = "systemd-network";
      group = "systemd-network";
    };
  };
  systemd = {
    network = {
      wait-online.anyInterface = true;
      enable = true;
      netdevs = {
        vmbr0 = {
          netdevConfig = {
            Kind = "bridge";
            Name = "vmbr0";
          };
        };
      };
      networks = {
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
          dhcpV6Config = { RouteMetric = 2048; };
          routes = [{
            Gateway = "_dhcp4";
            InitialCongestionWindow = 100;
            InitialAdvertisedReceiveWindow = 100;
          }];
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
          dhcpV6Config = { RouteMetric = 1024; };
          routes = [{
            routeConfig = {
              Gateway = "_dhcp4";
              InitialCongestionWindow = 100;
              InitialAdvertisedReceiveWindow = 100;
            };
          }];
        };
        "20-lan" = {
          matchConfig.MACAddress = "C8:1F:66:E6:7A:52";
          linkConfig.RequiredForOnline = "no";
          address = [ "10.18.0.1/24" ];
          networkConfig = { DHCPServer = true; };
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
          matchConfig.MACAddress = "C8:1F:66:E6:7A:54";
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
          linkConfig.RequiredForOnline = "no";
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
    firewall = {
      enable = true;
      allowedUDPPorts = [ 5201 ];
      allowedTCPPorts = [ 22 80 443 5201 ];
      allowPing = true;
      trustedInterfaces = [ "vmbr0" config.services.tailscale.interfaceName ];
    };
    nat = {
      enable = true;
      enableIPv6 = false;
      externalInterface = "enp68s0";
      internalInterfaces = [ "eno2" ];
    };
    wireguard = {
      enable = true;
      interfaces = {
        "wg0" = {
          ips = [ "10.75.0.2/32" "147.135.125.66/32" ];
          listenPort = 51820;
          privateKeyFile = config.age.secrets.wg0-private-key.path;
          # We'll set the routes ourselfs
          allowedIPsAsRoutes = false;
          table = 9999;
          postSetup = ''
            ${pkgs.iproute2}/bin/ip route add default via 10.75.0.2 dev wg0 table 9999
            ${pkgs.iproute2}/bin/ip rule add from 147.135.125.66 table 9999
          '';
          postShutdown = ''
            ${pkgs.iproute2}/bin/ip rule delete from 147.135.125.66 table 9999
          '';
          peers = [{
            publicKey = "2QZuyQ+Owa5AyOBlq2q75PaPnji/FOMteEVh35kKYzY=";
            endpoint = "router.cloud.shortcord.com:51820";
            persistentKeepalive = 15;
            allowedIPs = [ "0.0.0.0/0" "::/0" ];
          }];
        };
      };
    };
  };
}
