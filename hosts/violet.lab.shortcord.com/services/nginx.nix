{ pkgs, config, ... }: {
  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    recommendedBrotliSettings = true;
    streamConfig = ''
      upstream twitch {
        hash $remote_addr consistent;
        server ingest.global-contribute.live-video.net:1935;
      }
      upstream owncast {
        server owncast.owo.solutions:1935;
      }
      
      server {
        listen 100.64.0.4:1935 reuseport;
        proxy_pass twitch;
      }
      server {
        listen 100.64.0.4:1936 reuseport;
        proxy_pass owncast;
      }
      '';
  };
}
