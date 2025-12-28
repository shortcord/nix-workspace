{ config, pkgs, name, ... }:
let
 searxConfig = config.services.searx;
in
{
    age.secrets = {
        searxng-env = {
        file = ../../../secrets/${name}/searxng.age;
        };
    };
    systemd.services.searx-limiter-copy = {
        description = "Copy SearXNG limiter config to /run/searx";
        requires = [ "searx-init.service" ];
        after = [ "searx-init.service" ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.coreutils}/bin/ls -s /etc/searxng/limiter.toml /run/searx/limiter.toml";
            User = "searx";
            RemainAfterExit = "yes";
            RuntimeDirectory = "searx";
            RuntimeDirectoryMode = "0750";
            RuntimeDirectoryPreserve = "yes";
        };
    };
    services = {
        nginx.virtualHosts."${searxConfig.domain}" = {
            kTLS = true;
            http2 = true;
            http3 = true;
            forceSSL = true;
            enableACME = true;
        };
        searx = {
            enable = true;
            configureUwsgi = true;
            configureNginx = true;
            redisCreateLocally = true;
            domain = "search.owo.solutions";
            settings = {
                use_default_settings = true;
                general = {
                    instance_name = "OWO Search";
                    instance_description = "A privacy-respecting metasearch engine operated by a internet mouse.";
                    instance_contact = "mailto:short@shortcord.com";
                };
                server = {
                    secret_key = "$SEARX_SECRET_KEY";
                    public_instance = true;
                    image_proxy = true;
                };
                search.formats = [ "html" "json" ];
                service.limiter = true;
            };
            limiterSettings = {
                botdetection = {
                    ipv4_prefix = 32;
                    ipv6_prefix = 48;
                    trusted_proxies = [ "127.0.0.1/32" ];
                    ip_limit.filter_link_local = false;
                    ip_lists = {
                        ip_pass = [ "100.64.0.0/24" ];
                        pass_searxng_org = true;
                    };
                };
            };
            environmentFile = config.age.secrets.searxng-env.path;
            uwsgiConfig = {
                disable-logging = true;
                socket = "/run/searx/uwsgi.sock";
                chmod-socket = "660";
            };
        };
    };
}