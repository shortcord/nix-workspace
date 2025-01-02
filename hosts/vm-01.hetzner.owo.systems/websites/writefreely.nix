{ config, pkgs, ... }: 
let 
  cfg = config.services.writefreely;

  # The module does this which imo is stupid, this should be it's own package
  # We are pulling it out here so that we can have nginx return the content due to some odd issue with writefreely
  # plus making nginx do that is just better in general
  static_assets = pkgs.stdenvNoCC.mkDerivation {
    pname = "writefreely-assets";

    inherit (cfg.package) version src;

    nativeBuildInputs = with pkgs.nodePackages; [ less ];

    buildPhase = ''
      mkdir -p $out

      cp -r static $out/
    '';

    installPhase = ''
      less_dir=$src/less
      css_dir=$out/static/css

      lessc $less_dir/app.less $css_dir/write.css
      lessc $less_dir/fonts.less $css_dir/fonts.css
      lessc $less_dir/icons.less $css_dir/icons.css
      lessc $less_dir/prose.less $css_dir/prose.css
    '';
  };
in {
  services.writefreely = {
    enable = true;
    host = "blog.mousetail.dev";
    acme.enable = true;
    nginx = {
      enable = false;
      forceSSL = true;
    };
    database = {
      type = "sqlite3";
      name = "writefreely";
    };
    admin.name = "short";
    settings.app.single_user = true;
    settings.server = {
      static_parent_dir = "${static_assets}";
      port = 18080;
    };
  };
  services.nginx.virtualHosts."${cfg.host}" = {
    kTLS = true;
    http2 = true;
    http3 = true;
    forceSSL = true;
    enableACME = true;
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:18080";
      };
      "~ ^/(css|img|js|fonts)/" = {
        root = "${static_assets}/static";
      };
    };
  };
}
