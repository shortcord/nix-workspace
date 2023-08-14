{ pkgs, config, lib, ... }: {
  age.secrets.promtailPassword = {
    file = ../../secrets/general/promtailPassword.age;
    owner = "promtail";
    group = "promtail";
  };
  services = {
    rsyslogd = {
      enable = true;
      defaultConfig = ''
        *.* action(type="omfwd" protocol="tcp" target="127.0.0.1" port="1514" Template="RSYSLOG_SyslogProtocol23Format" TCP_Framing="octet-counted" KeepAlive="on")
      '';
    };
    promtail = {
      enable = true;
      configuration = {
        server = { disable = true; };
        client = {
          url = "https://loki.vm-01.hetzner.owo.systems/loki/api/v1/push";
          basic_auth = {
            username = "loki";
            password_file = config.age.secrets.promtailPassword.path;
          };
        };
        scrape_configs = [{
          job_name = "syslog";
          syslog = {
            listen_address = "127.0.0.1:1514";
            listen_protocol = "tcp";
            idle_timeout = "60s";
            label_structured_data = true;
            labels = { job = "syslog"; };
          };
          relabel_configs = [
            { # Set hostname
              source_labels = [ "__syslog_message_hostname" ];
              target_label = "host";
            }
            { # Drop if service tag is empty
              source_labels = [ "__service__" ];
              regex = "";
              action = "drop";
            }
          ];
        }];
      };
    };
  };
}
