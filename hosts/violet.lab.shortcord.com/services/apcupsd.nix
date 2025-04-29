{ name, pkgs, lib, config, ... }: {
  services = {
    apcupsd = {
      enable = true;
      configText = ''
        UPSNAME primary
        UPSTYPE usb
        POLLTIME 1
        NETSERVER on
        NISIP 127.0.0.1
        NISPORT 3551
        BATTERYLEVEL 10
        MINUTES 3
      '';
    };
    prometheus.exporters = {
      apcupsd = lib.mkIf config.services.apcupsd.enable {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
