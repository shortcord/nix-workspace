{ config, pkgs, lib, ... }:
let
  cfg = config.services.pterodactyl.wings;
in {
  options = {
    services.pterodactyl.wings = {
      enable = lib.mkEnableOption "Pterodactyl Wings";
      configFile = lib.mkOption {
        default = "/var/lib/pterodactyl/config.yaml";
        type = lib.types.str;
        description = lib.mkDoc "Manual Config path. Must be in a location that can be written to.";
      };
      package = lib.mkOption {
        default = pkgs.pterodactylWings;
        defaultText = lib.literalExpression "pkgs.pterodactylWings";
        type = lib.types.package;
      };
      openFirewall = lib.mkOption {
        default = false;
        type = lib.types.bool;
      };
      allocatedTCPPorts = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.port;
      };
      allocatedUDPPorts = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.port;
      };
      daemonPort = lib.mkOption { 
        type = lib.types.port;
        default = 4443;
      };
      sftpPort = lib.mkOption {
        type = lib.types.port;
        default = 2022;
      };
    };
  };
  config = lib.mkIf (cfg.enable) {
    virtualisation.docker.enable = true;
    users.users.pterodactyl = {
      isNormalUser = true;
      extraGroups = [ "docker" ];
    };
    networking.firewall = lib.mkIf (cfg.openFirewall) {
      allowedTCPPorts = cfg.allocatedTCPPorts;
      allowedUDPPorts = cfg.allocatedUDPPorts;
    };
    systemd.services."wings" = {
      after = [ "network.target" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      startLimitBurst = 30;
      startLimitIntervalSec = 180;
      restartTriggers = [ "/etc/pterodactyl/wings.yaml" ];
      serviceConfig = {
        User = "root";
        LimitNOFILE = 4096;
        PIDFile = "/run/wings/daemon.pid";
        ExecStart = "${cfg.package}/bin/wings --config ${cfg.configFile}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}