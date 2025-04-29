{ pkgs, config, ... }: {
  security.acme.certs = {
    "ipfs.${config.networking.fqdn}" = {
      inheritDefaults = true;
      dnsProvider = "pdns";
      environmentFile = config.age.secrets.acmeCredentialsFile.path;
      webroot = null;
    };
    "ipns.${config.networking.fqdn}" = {
      inheritDefaults = true;
      dnsProvider = "pdns";
      environmentFile = config.age.secrets.acmeCredentialsFile.path;
      webroot = null;
    };
  };
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
      enableGC = false;
      autoMigrate = false;
      localDiscovery = true;
      settings = {
        Experimental.FilestoreEnabled = true;
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
          Peers = [{
            Addrs = [
              "/dns4/ipfs-01.owo.systems/tcp/4001"
              "/dns6/ipfs-01.owo.systems/tcp/4001"
            ];
            ID = "12D3KooWNGmh5EBpPBXGGcFnrMtBW6u9Z61HgyHAobjo2ANhq1kL";
          }];
        };
        Datastore = { StorageMax = "1000GB"; };
        Addresses = {
          Api = [ "/ip4/127.0.0.1/tcp/5001" ];
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
