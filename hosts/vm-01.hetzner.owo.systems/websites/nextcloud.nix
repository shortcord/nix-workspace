{ name, pkgs, lib, config, ... }: {
  age.secrets = {
    nextcloudDbPass = {
      file = ../../../secrets/${name}/nextcloudDbPass.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    nextcloudAdminPass = {
      file = ../../../secrets/${name}/nextcloudAdminPass.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    nextcloudS3Secret = {
      file = ../../../secrets/${name}/nextcloudS3Secret.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
  };
  services = {
    nextcloud = {
      enable = true;
      https = true;
      package = pkgs.nextcloud30;
      hostName = "nextcloud.owo.solutions";
      webfinger = true;
      database.createLocally = false;
      maxUploadSize = "10G";
      configureRedis = true;
      extraOptions = {
        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
        ];
      };
      config = {
        dbtype = "mysql";
        dbpassFile = config.age.secrets.nextcloudDbPass.path;
        dbhost = "ns2.short.ts.shortcord.com";
        defaultPhoneRegion = "US";
        trustedProxies = [ "127.0.0.1" ];
        adminpassFile = config.age.secrets.nextcloudAdminPass.path;
        objectstore.s3 = {
          enable = true;
          region = "de-01";
          useSsl = true;
          usePathStyle = true;
          hostname = "storage.owo.systems";
          bucket = "shortcord-nextcloud";
          key = "nextcloud";
          secretFile = config.age.secrets.nextcloudS3Secret.path;
          autocreate = false;
        };
      };
    };
    nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
      kTLS = true;
      http2 = true;
      http3 = true;
      forceSSL = true;
      enableACME = true;
    };
  };
}
