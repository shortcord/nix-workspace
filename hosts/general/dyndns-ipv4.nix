{ pkgs, config, ... }: {
  age.secrets.pdnsApiKey.file = ../../secrets/general/pdnsApiKey.age;
  systemd = {
    timers = {
      "update-dyndns-ipv4" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "update-dyndns-ipv4.service";
        };
      };
    };
    services = {
      "update-dyndns-ipv4" = {
        script = ''
          set -eu
          source ${config.age.secrets.pdnsApiKey.path}
          ${pkgs.curl}/bin/curl -sf --user "''${API_USERNAME}:''${API_PASSWORD}" https://powerdns-admin.vm-01.hetzner.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip=$(${pkgs.curl}/bin/curl -sf http://ipv4.mousetail.dev/)
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
