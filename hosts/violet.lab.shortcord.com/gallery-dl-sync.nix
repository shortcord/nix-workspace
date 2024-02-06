{ name, pkgs, lib, config, ... }:
let
  pages = pkgs.writeText "pages.txt" ''
    # Favs
    https://e621.net/posts?tags=fav%3AShortCord

    # Artists
    https://e621.net/posts?tags=vlue_%28maynara%29
    https://e621.net/posts?tags=maynara
    https://e621.net/posts?tags=ark_warrior
    https://e621.net/posts?tags=ferris_argyle
    https://e621.net/posts?tags=somik
    https://e621.net/posts?tags=100racs
    https://e621.net/posts?tags=nicoya
    https://e621.net/posts?tags=deepstroke
    https://e621.net/posts?tags=codyblue-731
    https://e621.net/posts?tags=marsminer
    https://e621.net/posts?tags=mawmain
    https://e621.net/posts?tags=twang
    https://e621.net/posts?tags=deymos
    https://e621.net/posts?tags=quotefox
    https://e621.net/posts?tags=kittydee
    https://e621.net/posts?tags=rattfood
    https://e621.net/posts?tags=spikedmauler
    https://e621.net/posts?tags=ni70
    https://e621.net/posts?tags=zeiro
    https://e621.net/posts?tags=sigma_x
    https://e621.net/posts?tags=areye_(artist)
    https://e621.net/posts?tags=ultrabondagefairy
    https://e621.net/posts?tags=sunshiu
    https://e621.net/posts?tags=ulitochka
    https://e621.net/posts?tags=nenkoket
    https://e621.net/posts?tags=tekilao
    https://e621.net/posts?tags=wizzikt
    https://e621.net/posts?tags=kurus
    https://e621.net/posts?tags=delki
    https://e621.net/posts?tags=zonkpunch
    https://e621.net/posts?tags=jay_naylor
    https://e621.net/posts?tags=m-preg
    https://e621.net/posts?tags=lazysnout
    https://e621.net/posts?tags=fozzey
    https://e621.net/posts?tags=kiwa_flowcat
    https://e621.net/posts?tags=tsudamaku
    https://e621.net/posts?tags=punkypanda
    https://e621.net/posts?tags=cupofuwu
    https://e621.net/posts?tags=canphem
    https://e621.net/posts?tags=spincraze

    # Characters
    https://e621.net/posts?tags=texi_%28yitexity%29

    # Artists
    https://danbooru.donmai.us/posts?tags=oofxyphxia
    https://danbooru.donmai.us/posts?tags=morifumi
    https://danbooru.donmai.us/posts?tags=kalsept
    https://danbooru.donmai.us/posts?tags=muoto
    https://danbooru.donmai.us/posts?tags=zzz_(orchid-dale)
    https://danbooru.donmai.us/posts?tags=torriet
    https://danbooru.donmai.us/posts?tags=koromo_take
    https://danbooru.donmai.us/posts?tags=kuroduki_(pieat)
    https://danbooru.donmai.us/posts?tags=krekkov
    https://danbooru.donmai.us/posts?tags=nurunurubouzu
    https://danbooru.donmai.us/posts?tags=shinya_yuda
    https://danbooru.donmai.us/posts?tags=samsara_(shuukeura)
    https://danbooru.donmai.us/posts?tags=lobsteranian
    https://danbooru.donmai.us/posts?tags=snale
    https://danbooru.donmai.us/posts?tags=kirushi
    https://danbooru.donmai.us/posts?tags=pepero_(prprlo)
    https://danbooru.donmai.us/posts?tags=4qw5
    https://danbooru.donmai.us/posts?tags=2n5
    https://danbooru.donmai.us/posts?tags=glidesloe
    https://danbooru.donmai.us/posts?tags=the_atko
    https://danbooru.donmai.us/posts?tags=aki_(1360505188)

    # Characters
    https://danbooru.donmai.us/posts?tags=nazrin
    https://danbooru.donmai.us/posts?tags=noelle_(genshin_impact)
    https://danbooru.donmai.us/posts?tags=bridget_(guilty_gear)

    # General
    # https://danbooru.donmai.us/posts?tags=yuri+rating:general+-meme
    # https://danbooru.donmai.us/posts?tags=maid+-furry+rating%3Ag
    # https://danbooru.donmai.us/posts?tags=maid
    # https://danbooru.donmai.us/posts?tags=kimono
    https://danbooru.donmai.us/posts?tags=food_focus
    https://danbooru.donmai.us/posts?tags=signalis

    # Artists
    https://www.pixiv.net/en/users/32603125
    https://www.pixiv.net/en/users/22298878
    https://www.pixiv.net/en/users/3439325
    https://www.pixiv.net/en/users/67442991
    https://www.pixiv.net/en/users/12450448
    https://www.pixiv.net/en/users/526122

    # Artists
    https://rule34.xxx/index.php?page=post&s=list&tags=prprlo
    https://rule34.xxx/index.php?page=post&s=list&tags=pepero_(prprlo)
    https://rule34.xxx/index.php?page=post&s=list&tags=voidnosferatu

    # Characters
    https://rule34.xxx/index.php?page=post&s=list&tags=krekk0v+-gore+-death
  '';
  dlDirectory = "/var/gallery-dl";
in {
  fileSystems = {
    "/var/gallery-dl" = {
      device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
      fsType = "btrfs";
      options = [
        "noatime"
        "degraded"
        "compress=zstd"
        "discard=async"
        "space_cache=v2"
        "subvolid=890"
      ];
    };
  };
  age.secrets.gallery-dl-config.file =
    ../../secrets/${name}/gallery-dl-config.age;
  environment.etc."gallery-dl-pages.txt".source = pages;
  systemd = {
    timers = {
      "gallery-dl-process" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnActiveSec = "30m";
          OnUnitActiveSec = "30m";
          Unit = "gallery-dl-process.service";
        };
      };
    };
    services = {
      gallery-dl-process = {
        after = [ "network.target" "gallery-dl-init-dirs.service" ];
        requires = [ "gallery-dl-init-dirs.service" ];
        description = "GalleryDL";
        script = ''
          set -eu

          ${pkgs.flock}/bin/flock -n /tmp/gallery-dl-process.lockfile \
            ${pkgs.gallery-dl}/bin/gallery-dl \
              --config "${config.age.secrets.gallery-dl-config.path}" \
              --input-file "/etc/gallery-dl-pages.txt" \
              --destination "${dlDirectory}" \
              --download-archive "${dlDirectory}/archive.db" 

          # Heartbeat Check
          ${pkgs.curl}/bin/curl -sf 'https://uptime.vm-01.hetzner.owo.systems/api/push/G07VWI97qv'

          exit 0
        '';
        serviceConfig = {
          Type = "oneshot";
          SyslogIdentifier = "gallery-dl-process";
        };
      };
      gallery-dl-init-dirs = {
        after = [ "network.target" ];
        script = ''
          mkdir -p "${dlDirectory}"
        '';
        serviceConfig = {
          Type = "oneshot";
          SyslogIdentifier = "gallery-dl-init-dirs";
        };
      };
    };
  };
  services.phpfpm.pools."h5ai" = {
    user = config.services.nginx.user;
    group = config.services.nginx.group;
    phpPackage = pkgs.php81;
    settings = {
      pm = "dynamic";
      "listen.owner" = config.services.nginx.user;
      "pm.max_children" = 30;
      "pm.start_servers" = 10;
      "pm.min_spare_servers" = 10;
      "pm.max_spare_servers" = 20;
      "pm.max_requests" = 500;
    };
    phpEnv."PATH" = lib.makeBinPath [
      pkgs.ffmpeg
      pkgs.imagemagick
      pkgs.gnutar
      pkgs.zip
      pkgs.coreutils
    ];
  };
  services.nginx = {
    virtualHosts = {
      "filebrowser.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;

        root = dlDirectory;

        locations = {
          "/" = { index = "/_h5ai/public/index.php"; };
          "~ \\.php$" = {
            extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools."h5ai".socket};
              fastcgi_index index.php;
            '';
            fastcgiParams = { "test" = "test"; };
          };
        };
      };
    };
  };
}
