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
            use_default_settings = {
                engines = {
                    remove = [ "duckduckgo" ];
                };
            };
            server.secret_key = "$SEARX_SECRET_KEY";
            search.formats = [ "html" "json" ];
            server.image_proxy = true;
            service.limiter = true;
        };
        limiterSettings = {
            trusted_proxies = [ "127.0.0.1/8" ];
            botdetection = {
                ipv4_prefix = 32;
                ipv6_prefix = 48;
                ip_limit.filter_link_local = false;
                ip_lists = {
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