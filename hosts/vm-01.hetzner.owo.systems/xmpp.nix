{ config, ... }:
let
  prosodyUser = config.services.prosody.user;
  prosodyGroup = config.services.prosody.group;
  homeDir = "${config.users.users."${prosodyUser}".home}";
  domainName = "xmpp.owo.systems";
in {
  age.secrets.acmeCredentialsFile.file =
    ../../secrets/general/acmeCredentialsFile.age;
  security.acme = {
    certs = {
      "${domainName}" = {
        webroot = null;
        credentialsFile = config.age.secrets.acmeCredentialsFile.path;
        dnsProvider = "pdns";
        reloadServices = [ "prosody.service" ];
        postRun = ''
          cp fullchain.pem "${homeDir}/"
          cp key.pem "${homeDir}/"
          chown ${prosodyUser}:${prosodyGroup} "${homeDir}/fullchain.pem"
          chown ${prosodyUser}:${prosodyGroup} "${homeDir}/key.pem"
        '';
        extraDomainNames =
          [ "upload.${domainName}" "conference.${domainName}" "mousetail.dev" ];
      };
    };
  };
  networking.firewall = {
    allowedTCPPorts = [
      # Prosody XMPP
      5000
      5222
      5269
      5281
      5347
      5582
    ];
  };
  services = {
    prosody = {
      enable = true;
      admins = [ "short@mousetail.dev" ];
      allowRegistration = false;
      modules = { server_contact_info = true; };
      ssl = {
        cert = "${homeDir}/fullchain.pem";
        key = "${homeDir}/key.pem";
      };
      virtualHosts = {
        "mousetail.dev" = {
          enabled = true;
          domain = "mousetail.dev";
          ssl = {
            cert = "${homeDir}/fullchain.pem";
            key = "${homeDir}/key.pem";
          };
        };
      };
      muc = [{ domain = "conference.${domainName}"; }];
      uploadHttp = {
        uploadFileSizeLimit = "2000*1024*1024";
        domain = "upload.${domainName}";
      };
    };
    nginx = {
      virtualHosts = {
        "${domainName}" = {
          serverAliases = [ "upload.${domainName}" "conference.${domainName}" ];
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { return = "302 https://mousetail.dev"; };
        };
      };
    };
  };
}
