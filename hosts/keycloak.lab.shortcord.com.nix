{ name, nodes, pkgs, lib, config, ... }: {
  imports = [ ./${name}/hardware.nix ];

  age.secrets.pdnsApiKey.file = ../secrets/general/pdnsApiKey.age;
  systemd = {
    timers = {
      "update-dyndns-ipv6" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "update-dyndns-ipv6.service";
        };
      };
    };
    services = {
      "update-dyndns-ipv6" = {
        script = ''
          set -eu
          source ${config.age.secrets.pdnsApiKey.path}
          ${pkgs.curl}/bin/curl -sf --user "''${API_USERNAME}:''${API_PASSWORD}" https://powerdns-admin.vm-01.hetzner.owo.systems/nic/update\?hostname=keycloak.lab.shortcord.com\&myip=$(${pkgs.curl}/bin/curl -sf http://ipv6.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };

}
