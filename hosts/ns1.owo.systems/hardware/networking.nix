{ name, pkgs, lib, config, ... }: {
  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = false;
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "BC:24:11:7C:3B:86";
        networkConfig = {
          DHCP = "yes";
        };
      };
    };
  };
}
