{ config, ... }: {
  security.acme = {
    certs = {
      "xmpp.${config.networking.fqdn}" = {
        reloadServices = [ "prosody.service" ];
        postRun = ''
          cp fullchain.pem "${
            config.users.users."${config.services.prosody.user}".home
          }/"
          cp key.pem "${
            config.users.users."${config.services.prosody.user}".home
          }/"
          chown ${config.services.prosody.user}:${config.services.prosody.group} "${
            config.users.users."${config.services.prosody.user}".home
          }/fullchain.pem"
          chown ${config.services.prosody.user}:${config.services.prosody.group} "${
            config.users.users."${config.services.prosody.user}".home
          }/key.pem"
        '';
        extraDomainNames = [
          "upload.xmpp.${config.networking.fqdn}"
          "conference.xmpp.${config.networking.fqdn}"
        ];
      };
    };
  };
  services.prosody = {
    enable = true;
    admins = [ "short@xmpp.${config.networking.fqdn}" ];
    ssl = {
      cert = "${
          config.users.users."${config.services.prosody.user}".home
        }/fullchain.pem";
      key =
        "${config.users.users."${config.services.prosody.user}".home}/key.pem";
    };
    virtualHosts = {
      "xmpp.${config.networking.fqdn}" = {
        enabled = true;
        domain = "xmpp.${config.networking.fqdn}";
        ssl = {
          cert = "${
              config.users.users."${config.services.prosody.user}".home
            }/fullchain.pem";
          key = "${
              config.users.users."${config.services.prosody.user}".home
            }/key.pem";
        };
      };
    };
    muc = [{ domain = "conference.xmpp.${config.networking.fqdn}"; }];
    uploadHttp = { domain = "upload.xmpp.${config.networking.fqdn}"; };
  };
}
