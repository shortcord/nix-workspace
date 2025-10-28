{ name, pkgs, lib, config, ... }: {
  services = {
    resolved.enable = false;
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
      forwardZones = { "ts.shortcord.com" = "100.100.100.100"; };
    };
  };
}
