{ pkgs, config, ... }: {
  fileSystems = {
    "/var/lib/ipfs" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=605"
      ];
    };
  };
  services = {
    nginx = {
      virtualHosts = {
        "ipfs.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = { proxyPass = "http://localhost:8080"; };
        };
        "ipns.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = { proxyPass = "http://localhost:8080"; };
        };
      };
    };
    kubo = {
      enable = true;
      emptyRepo = true;
      enableGC = true;
      autoMigrate = false;
      localDiscovery = true;
      settings = {
        PublicGateways = {
          "${config.networking.fqdn}" = {
            Paths = [ "/ipfs" "/ipns" ];
            UseSubdomains = true;
          };
        };
        Bootstrap = [
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN"
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa"
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb"
          "/dnsaddr/bootstrap.libp2p.io/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt"
          "/ip4/104.131.131.82/tcp/4001/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ"
          "/ip4/104.131.131.82/udp/4001/quic/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ"
        ];
        Peering = {
          Peers = [
            {
              Addrs = [ 
                "/dns4/ipfs-01.owo.systems/tcp/4001"
                "/dns6/ipfs-01.owo.systems/tcp/4001"
              ];
              ID = "12D3KooWNGmh5EBpPBXGGcFnrMtBW6u9Z61HgyHAobjo2ANhq1kL";
            }
            {
              Addrs = [ ];
              ID = "12D3KooWDdHkmE24QM4LdUotNJhLRw4vjT3hEDGxCdsB35wb1usb";
            }
            {
              Addrs = [ ];
              ID = "12D3KooWE3gerBqRL1YAQf8dkokfmbgVSo6DcDtxW3NTsJJRqbux";
            }
            {
              Addrs = [ ];
              ID = "12D3KooWM63pJ1xhDjqKvH8bEyzowwmfB5tP9UndMP2T2WjDBF7Y";
            }
            {
              Addrs = [ ];
              ID = "12D3KooWQvpkLdMxMX2xfBGe44nQu2BiLyiuaLvYSXL15Cfwiowk";
            }
            {
              Addrs = [ ];
              ID = "12D3KooWQf7Z78nUizJyhETrKx1NgqbxPTRoQ8NhZAeSjhQWRRnQ";
            }
            {
              Addrs = [ "/dns6/dl.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWQvvJkr8fqUAJWcwe6Tysng3AQyKtSBnTG85rW5vm4B67";
            }
            {
              Addrs = [ "/dns6/ipfs.home.bsocat.net/tcp/4001" ];
              ID = "12D3KooWGHPei7QWiX8vJjHgEkoC4QDWcGKdJf9bE8noP1dAWS21";
            }
            {
              Addrs = [ "/dns6/gnutoo.home.bsocat.net/tcp/4001" ];
              ID = "12D3KooWNoPhenCQSsdfKJvJ8g2R1bHbw7M7s5arykhqJCVd5F2B";
            }
            {
              Addrs = [ "/dns6/ipfs1.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWFkQFKVSgmDfUggx5de5wSbAtfegBnashkP8VN8rESRUX";
            }
            {
              Addrs = [ "/dns6/ipfs2.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWLSr7JRSYooakhq58vZowUcCaW4ff31tHaGTrWDDaCL8W";
            }
            {
              Addrs = [ "/dns6/ipfs3.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWS3ZiwYPxL4iB3xh32oQs7Cm61ZN7sCsQXhvTGyfybn91";
            }
          ];
        };
        Datastore = { StorageMax = "1000GB"; };
        Addresses = {
          Api = [ "/ip4/127.0.0.1/tcp/5001" "/ip4/10.18.0.1/tcp/5001" ];
          Gateway = "/ip4/127.0.0.1/tcp/8080";
        };
      };
    };
  };
  systemd.services.ipfs = {
    serviceConfig = {
      MemoryAccounting = "yes";
      MemoryHigh = "5G";
      MemoryMax = "10G";
    };
  };
}
