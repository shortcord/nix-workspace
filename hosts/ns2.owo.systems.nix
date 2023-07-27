{ name, nodes, pkgs, lib, config, ... }: {
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
  };

  swapDevices = [{ device = "/.swapfile"; }];
  zramSwap.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = false;

  system.stateVersion = "22.11";

  boot = {
    growPartition = true;
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [ "ata-piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };
    initrd = {
      availableKernelModules =
        [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
      kernelModules = [ ];
    };
  };

  age.secrets = {
    wireguardPrivateKey.file = ../secrets/${name}/wireguardPrivateKey.age;
    wireguardPresharedKey.file = ../secrets/${name}/wireguardPresharedKey.age;
    powerdnsConfig.file = ../secrets/${name}/powerdnsConfig.age;
  };

  nix = {
    buildMachines = [{
      hostName = "violet.lab.shortcord.com";
      systems = [ "x86_64-linux" "i686-linux" ];
      protocol = "ssh-ng";
      maxJobs = 20;
      sshUser = "remotebuild";
      sshKey = config.age.secrets.distributedUserSSHKey.path;
    }];
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "10-wan" = {
          matchConfig.MACAddress = "56:00:04:63:08:52";
          networkConfig = {
            DHCP = "no";
            DNS = [ "127.0.0.1" "::1" ];
            Address = [
              "66.135.9.121/23"
              "2001:19f0:1000:1512:5400:04ff:fe63:0852/64"
            ];
            Gateway = "66.135.8.1";
            IPv6AcceptRA = true;
          };
        };
      };
    };
  };

  networking = {
    hostName = "ns2";
    domain = "owo.systems";
    useDHCP = false;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 51820 ];
      allowedTCPPorts = [ 53 22 80 443 ];
      allowPing = true;
      trustedInterfaces = [ "wg1" ];
    };
    wireguard = {
      enable = true;
      interfaces = {
        wg1 = {
          ips = [ "10.7.210.1/32" ];
          listenPort = 51820;
          privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
          peers = [
            {
              publicKey = "x8o7GM5Fk1EYZK9Mgx4/DIt7DxAygvKg310G6+VHhUs=";
              persistentKeepalive = 15;
              allowedIPs = [ "10.7.210.2/32" ];
            }
            {
              publicKey = "iCm6s21gpwlvaVoBYw0Wyaa39q/REIa+aTFXvkBFYEQ=";
              persistentKeepalive = 15;
              allowedIPs = [ "10.7.210.3/32" ];
            }
          ];
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ vim wget curl ];

  services = {
    resolved.enable = false;
    openssh = {
      enable = true;
      passwordAuthentication = false;
    };
    fail2ban = { enable = true; };
    mysql = {
      package = pkgs.mariadb;
      enable = true;
      replication = {
        role = "master";
        serverId = 2;
        ## This information is only here to prevent the init script
        # from erroring out during deployment 
        masterUser = "replication_user";
        masterPassword = "temppassword";
        slaveHost = "10.7.210.2";
      };
    };
    powerdns = {
      enable = true;
      secretFile = config.age.secrets.powerdnsConfig.path;
      extraConfig = ''
        resolver=[::1]:53
        expand-alias=yes

        local-address=66.135.9.121:53, [2001:19f0:1000:1512:5400:04ff:fe63:0852]:53

        webserver=yes
        webserver-address=127.0.0.1
        webserver-port=8081
        webserver-allow-from=127.0.0.1,::1
        api=yes
        api-key=$API_KEY

        launch=gmysql

        gmysql-port=3306
        gmysql-host=$SQL_HOST
        gmysql-dbname=$SQL_DATABASE
        gmysql-user=$SQL_USER
        gmysql-password=$SQL_PASSWORD
        gmysql-dnssec=yes
      '';
    };
    pdns-recursor = {
      enable = true;
      dns = {
        port = 53;
        address = [ "127.0.0.1" "::1" ];
      };
    };
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          openFirewall = false;
          port = 9100;
          listenAddress = "127.0.0.1";
        };
      };
    };
    postfix = {
      enable = true;
      config = {
        mynetworks = [ "127.0.0.0/8" "10.7.210.0/24" ];
        inet_interfaces = [ "127.0.0.1" "10.7.210.1" ];
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
        relayhost = "[smtp-relay.gmail.com]:587";

        smtp_always_send_ehlo = "yes";
        smtp_helo_name = "shortcord.com";
      };
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations = { "/" = { return = "302 https://shortcord.com"; }; };
        };
        "powerdns.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8081"; };
        };
      };
    };
  };
}
