{ name, nodes, pkgs, lib, config, modulesPath, ... }: {
  system.stateVersion = "24.11";

  imports = [ 
    (modulesPath + "/profiles/qemu-guest.nix") 
    ./general/all.nix
  ];

  swapDevices = [ ];
  zramSwap.enable = true;
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  nix = {
    buildMachines = [{
      hostName = "localhost";
      systems = [ "x86_64-linux" "i686-linux" ];
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
      maxJobs = 8;
    }];
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        matchConfig.MACAddress = "12:22:95:0e:10:6c";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
      };
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 22 80 443 ];
      allowPing = true;
    };
  };

  services = {
    qemuGuest.enable = true;
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
          openFirewall = true;
        };
      };
    };
  };

  age.secrets.nix-serve.file = ../secrets/${name}/nix-serve.age;
  services = {
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedBrotliSettings = true;
      virtualHosts = {
        "cache.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://${config.services.nix-serve.bindAddress}:${
                toString config.services.nix-serve.port
              }";
          };
        };
        "${config.networking.fqdn}" = lib.mkIf config.services.hydra.enable {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://${config.services.hydra.listenHost}:${
                toString config.services.hydra.port
              }";
          };
        };
      };
    };
    nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets.nix-serve.path;
      bindAddress = "127.0.0.1";
      port = 5000;
    };
    hydra = {
      enable = true;
      listenHost = "127.0.0.1";
      hydraURL = "https://${config.networking.fqdn}";
      notificationSender = "hydra@${config.networking.fqdn}";
      buildMachinesFiles = [ ];
      useSubstitutes = true;
    };
  };
}
