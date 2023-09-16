{ config, pkgs, lib, ... }:
let
  cfg = config.services.pterodactyl.wings;
  yamlType = (pkgs.formats.yaml { }).type;

  configFile = pkgs.writeTextFile {
    name = "wings.yaml";
    text = builtins.toJSON cfg.settings;
  };
in {
  options = {
    services.pterodactyl.wings = {
      enable = lib.mkEnableOption "Pterodactyl Wings";
      user = lib.mkOption {
        default = "pterodactyl";
        type = lib.types.str;
      };
      group = lib.mkOption {
        default = "pterodactyl";
        type = lib.types.str;
      };
      package = lib.mkOption {
        default = pkgs.pterodactyl-wings;
        defaultText = lib.literalExpression "pkgs.pterodactyl-wings";
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

      extraConfigFile = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.path;
      };

      settings = lib.mkOption {
        default = {};
        type = lib.types.nullOr (lib.types.submodule {
          freeformType = yamlType;
          options = {
            api = lib.mkOption {
              default = {};
              type = lib.types.nullOr (lib.types.submodule {
                freeformType = yamlType;
                options = {
                  host = lib.mkOption {
                    type = lib.types.str;
                    default = "0.0.0.0";
                  };
                  port = lib.mkOption {
                    type = lib.types.port;
                    default = 443;
                  };
                  ssl = lib.mkOption {
                    default = {};
                    type = lib.types.nullOr (lib.types.submodule {
                      freeformType = yamlType;
                      options = {
                        enabled = lib.mkOption {
                          default = false;
                          type = lib.types.bool;
                        };
                        cert = lib.mkOption {
                          default = null;
                          type = lib.types.nullOr lib.types.str;
                        };
                        key = lib.mkOption {
                          default = null;
                          type = lib.types.nullOr lib.types.str;
                        };
                      };
                    });
                  };
                };
              });
            };
            system = lib.mkOption {
              default = {};
              type = lib.types.nullOr (lib.types.submodule {
                freeformType = yamlType;
                options = {
                  root_directory = lib.mkOption {
                    default = "/var/lib/pterodactyl";
                    type = lib.types.str;
                  };
                  username = lib.mkOption {
                    default = cfg.user;
                    type = lib.types.str;
                  };
                  sftp = lib.mkOption {
                    default = {};
                    type = lib.types.nullOr (lib.types.submodule {
                      freeformType = yamlType;
                      options = {
                        bind_address = lib.mkOption {
                          default = "0.0.0.0";
                          type = lib.types.str;
                        };
                        bind_port = lib.mkOption {
                          default = 2022;
                          type = lib.types.port;
                        };
                      };
                    });
                  };
                };
              });
            };
            ignore_panel_config_updates = lib.mkOption {
              default = true;
              type = lib.types.bool;
            };
          };
        });
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
      allowedTCPPorts = [cfg.settings.api.port cfg.settings.system.sftp.bind_port ] ++ cfg.allocatedTCPPorts;
      allowedUDPPorts = cfg.allocatedUDPPorts;
    };
    systemd.services = {
      "wings" = {
        after = [ "network.target" ];
        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
        startLimitBurst = 30;
        startLimitIntervalSec = 180;
        preStart = lib.mkMerge [
          (lib.mkIf (cfg.extraConfigFile != null) ''
            ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' "${configFile}" "${cfg.extraConfigFile}" > "${cfg.settings.system.root_directory}/wings.yaml"
          '')
          (lib.mkIf (cfg.extraConfigFile == null) ''
            cp -L "${configFile}" "${cfg.settings.system.root_directory}/wings.yaml"
          '')
        ];
        serviceConfig = {
          User = "root";
          LimitNOFILE = 4096;
          PIDFile = "/run/wings/daemon.pid";
          ExecStart = "${cfg.package}/bin/wings --config \"${cfg.settings.system.root_directory}/wings.yaml\"";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
  };
}
