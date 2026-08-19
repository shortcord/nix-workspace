{ pkgs, ... }:
let
    gatewayChecker = ''
        set -euo pipefail

        PRIMARY_IF="eno1"
        BACKUP_IF="enp68s0"

        get_gw() {
            ${pkgs.iproute2}/bin/ip --json route show default dev "$1" | ${pkgs.jq}/bin/jq -r '.[0].gateway // empty'
        }

        check_wan() {
            local iface="$1"

            ${pkgs.iputils}/bin/ping -I "$iface" -c 2 -W 2 1.1.1.1 >/dev/null 2>&1 ||
            ${pkgs.iputils}/bin/ping -I "$iface" -c 2 -W 2 8.8.8.8 >/dev/null 2>&1
        }

        PRIMARY_GW="$(get_gw "''${PRIMARY_IF}" || true)"
        BACKUP_GW="$(get_gw "''${BACKUP_IF}" || true)"

        if [[ -z "$PRIMARY_GW" || -z "''${BACKUP_GW}" ]]; then
            ${pkgs.coreutils}/bin/echo "Missing gateway; primary=''${PRIMARY_GW} backup=''${BACKUP_GW}"
            exit 0
        fi

        if check_wan "''${PRIMARY_IF}"; then
            ${pkgs.iproute2}/bin/ip route replace default via "''${PRIMARY_GW}" dev "''${PRIMARY_IF}" metric 100
            ${pkgs.coreutils}/bin/echo primary
        elif check_wan "''${BACKUP_IF}"; then
            ${pkgs.iproute2}/bin/ip route replace default via "''${BACKUP_GW}" dev "''${BACKUP_IF}" metric 100
            ${pkgs.coreutils}/bin/echo backup
        else
            ${pkgs.coreutils}/bin/echo "Both WANs failed; keeping current route."
        fi
    '';
in {
    systemd = {
        timers = {
            "gateway-checker" = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "1m";
                    OnUnitActiveSec = "5m";
                    Unit = "gateway-checker.service";
                };
            };
        };
        services = {
            "gateway-checker" = {
                description = "Gateway Checker";
                after = [ "network.target" ];
                script = " ${gatewayChecker}";
                serviceConfig = {
                    Type = "oneshot";
                    SyslogIdentifier = "gateway-checker";
                };
            };
        };
    };
}