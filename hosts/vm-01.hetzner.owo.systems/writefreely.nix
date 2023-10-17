{ config, pkgs, ... }: {
  services.writefreely = {
    enable = true;
    host = "blog.mousetail.dev";
    acme.enable = true;
    nginx = {
      enable = true;
      forceSSL = true;
    };
    database = {
      type = "sqlite3";
      name = "writefreely";
    };
    admin.name = "short";
    settings.app.single_user = true;
  };
}
