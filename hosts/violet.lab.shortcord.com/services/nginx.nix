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
    streamConfig =
      "\n      upstream twitch {\n        hash $remote_addr consistent;\n        server ingest.global-contribute.live-video.net:1935;\n      }\n\n      upstream owncast {\n        server owncast.owo.solutions:1935;\n      }\n\n      server {\n        listen 100.64.0.4:1935 reuseport;\n        proxy_pass twitch;\n      }\n\n      server {\n        listen 100.64.0.4:1936 reuseport;\n        proxy_pass owncast;\n      }\n    ";
  };
}
