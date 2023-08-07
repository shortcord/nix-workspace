{ pkgs, config, ... }: {
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
      localDiscovery = false;
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

          ## ipfs-01.owo.systems
          "/dnsaddr/ipfs-01.owo.systems/p2p/12D3KooWNGmh5EBpPBXGGcFnrMtBW6u9Z61HgyHAobjo2ANhq1kL"
        ];
        Peering = {
          Peers = [
            {
              Addrs = [ ];
              ID = "12D3KooWM63pJ1xhDjqKvH8bEyzowwmfB5tP9UndMP2T2WjDBF7Y";
            }
            {
              Addrs = [ ];
              ID = "12D3KooWDJCyi3EAVBeisRkrRGtEPjEHNA3CKsmwbWbg5mM9eqvZ";
            }
            {
              Addrs = [
                "/ip6/2a01:4ff:f0:c73c::1/udp/4001/quic/p2p/12D3KooWJTJoJZ49CgoqYe4JnUfXaqDPYiG5bm1ssN6X4v8n9FF2/p2p-circuit"
              ];
              ID = "12D3KooWJo2f5EmnUmZFeWxVDHUKdpZmhQ9pVdJ2eQToxNyF5WNm";
            }
            {
              Addrs = [ "/dns6/ipfs1.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWFkQFKVSgmDfUggx5de5wSbAtfegBnashkP8VN8rESRUX";
            }
            {
              Addrs = [ "/dns6/ipfs.home.bsocat.net/tcp/4001" ];
              ID = "12D3KooWGHPei7QWiX8vJjHgEkoC4QDWcGKdJf9bE8noP1dAWS21";
            }
            {
              Addrs = [ "/dns6/ipfs2.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWLSr7JRSYooakhq58vZowUcCaW4ff31tHaGTrWDDaCL8W";
            }
            {
              Addrs = [ "/dns6/gnutoo.home.bsocat.net/tcp/4001" ];
              ID = "12D3KooWNoPhenCQSsdfKJvJ8g2R1bHbw7M7s5arykhqJCVd5F2B";
            }
            {
              Addrs = [ "/dns6/dl.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWQvvJkr8fqUAJWcwe6Tysng3AQyKtSBnTG85rW5vm4B67";
            }
            {
              Addrs = [ "/dns6/ipfs3.lxd.bsocat.net/tcp/4001" ];
              ID = "12D3KooWS3ZiwYPxL4iB3xh32oQs7Cm61ZN7sCsQXhvTGyfybn91";
            }
          ];
        };
        Datastore = { StorageMax = "1000GB"; };
        Addresses = { Gateway = "/ip4/127.0.0.1/tcp/8080"; };
      };
    };
  };
}
