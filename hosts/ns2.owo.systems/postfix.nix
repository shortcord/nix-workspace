{ name, nodes, pkgs, lib, config, ... }: {
  services = {
    postfix = {
      enable = true;
      settings.main = {
        mynetworks = [ "127.0.0.0/8" "10.7.210.0/24" "100.64.0.0/24" ];
        inet_interfaces = [ "127.0.0.1" "10.7.210.1" "100.64.0.10/32" ];
        relay_domains = [ "lilac.lab.shortcord.com" "shortcord.com" "owo.systems" "owo.solutions" "owo.gallery" "mousetail.dev" ];
        parent_domain_matches_subdomains = [ "relay_domains" ];

        # Allow connections from trusted networks only.
        smtpd_client_restrictions = [ "permit_mynetworks" "reject" ];

        # Enforce server to always ehlo
        smtpd_helo_required = "yes";
        # Don't talk to mail systems that don't know their own hostname.
        # With Postfix < 2.3, specify reject_unknown_hostname.
        #smtpd_helo_restrictions = [ "reject_unknown_hostname" ];
        # I don't like this but I'm at a loss as it sees the wireguard IP and I'm
        # not about to put that in DNS.
        smtpd_helo_restrictions = [ ];

        # Don't accept mail from domains that don't exist.
        smtpd_sender_restrictions = [ "reject_unknown_sender_domain" ];

        # Spam control: exclude local clients and authenticated clients
        # from DNSBL lookups.
        smtpd_recipient_restrictions = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          # reject_unauth_destination is not needed here if the mail
          # relay policy is specified under smtpd_relay_restrictions
          # (available with Postfix 2.10 and later).
          "reject_unauth_destination"
          "reject_rbl_client zen.spamhaus.org"
          "reject_rhsbl_reverse_client dbl.spamhaus.org"
          "reject_rhsbl_helo dbl.spamhaus.org"
          "reject_rhsbl_sender dbl.spamhaus.org"
        ];

        # Relay control (Postfix 2.10 and later): local clients and
        # authenticated clients may specify any destination domain.
        smtpd_relay_restrictions = [
          "permit_mynetworks"
          "permit_sasl_authenticated"
          "reject_unauth_destination"
        ];

        # Block clients that speak too early.
        smtpd_data_restrictions = [ "reject_unauth_pipelining" ];

        # Enforce mail volume quota via policy service callouts.
        # smtpd_end_of_data_restrictions =
        #   [ "check_policy_service unix:private/policy" ];

        smtp_sasl_auth_enable = "no";
        smtp_sasl_security_options = [ "noanonymous" ];
        smtp_tls_security_level = "encrypt";

        smtp_use_tls = "yes";
        relayhost = [ "[smtp-relay.gmail.com]:587" ];

        smtp_always_send_ehlo = "yes";
        smtp_helo_name = "shortcord.com";
      };
    };
  };
}
