{ name, pkgs, config, lib, ... }: {
  age.secrets = {
    acmeCredentialsFile.file = ../../secrets/general/acmeCredentialsFile.age;
    user-short.file = ../../secrets/${name}/email-short.env.age;
    user-noreply.file = ../../secrets/${name}/email-noreply.env.age;
  };
  security.acme = {
    certs = {
      "${config.mailserver.fqdn}" = {
        webroot = null;
        credentialsFile = config.age.secrets.acmeCredentialsFile.path;
        dnsProvider = "pdns";
      };
    };
  };
  networking = {
    firewall = lib.mkIf config.networking.firewall.enable {
      allowedTCPPorts = [ 80 443 ];
    };
  };
  services = {
    roundcube = {
      enable = true;
      hostName = "webmail.${config.networking.fqdn}";
      extraConfig = ''
        $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
        $config['smtp_user'] = "%u";
        $config['smtp_pass'] = "%p";
      '';
    };
  };
  mailserver = {
    enable = true;
    localDnsResolver = false;
    fqdn = "mail.${config.networking.fqdn}";
    domains = [ config.networking.fqdn ];
    certificateScheme = "acme";
    loginAccounts = {
      "short@${config.networking.fqdn}" = {
        hashedPasswordFile = config.age.secrets.user-short.path;
        aliases = [
          "postmaster@${config.networking.fqdn}"
          "abuse@${config.networking.fqdn}"
          "squeak@${config.networking.fqdn}"
        ];
      };
      "noreply@${config.networking.fqdn}" = {
        hashedPasswordFile = config.age.secrets.user-noreply.path;
        sendOnly = true;
      };
    };
  };
}
