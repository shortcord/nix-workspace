{ pkgs, config, ... }: {
  age.secrets.pdnsApiKey.file = ../../secrets/general/pdnsApiKey.age;
  systemd = {
    timers = {
      "update-dyndns" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1m";
          OnUnitActiveSec = "1m";
          Unit = "update-dyndns.service";
        };
      };
    };
    services = {
      "update-dyndns" = {
        script = let netConfig = config.systemd.network.networks."10-wan";
        in ''
          set -eu
          source ${config.age.secrets.pdnsApiKey.path}

          ipAddress4=$(${pkgs.iproute2}/bin/ip -j a show | ${pkgs.jq}/bin/jq -r '.[] | select(.address == "${netConfig.matchConfig.MACAddress}") | .addr_info[] | select(.scope == "global" and .family == "inet") | .local')
          ipAddress6=$(${pkgs.iproute2}/bin/ip -j a show | ${pkgs.jq}/bin/jq -r '.[] | select(.address == "${netConfig.matchConfig.MACAddress}") | .addr_info[] | select(.scope == "global" and .family == "inet6") | .local')

          ${pkgs.curl}/bin/curl -sf --user "''${API_USERNAME}:''${API_PASSWORD}" https://powerdns-admin.vm-01.hetzner.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip="''${ipAddress4}"
          ${pkgs.curl}/bin/curl -sf --user "''${API_USERNAME}:''${API_PASSWORD}" https://powerdns-admin.vm-01.hetzner.owo.systems/nic/update\?hostname=${config.networking.fqdn}\&myip="''${ipAddress6}"
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
