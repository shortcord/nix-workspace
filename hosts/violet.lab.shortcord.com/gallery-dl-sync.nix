{ pkgs, config, ... }:
let
  pages = pkgs.writeText "pages.txt" ''
    https://e621.net/posts?tags=fav%3AShortCord
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
  

    # Characters
    # https://danbooru.donmai.us/posts?tags=nazrin
    # https://danbooru.donmai.us/posts?tags=noelle_(genshin_impact)
    # https://danbooru.donmai.us/posts?tags=bridget_%28guilty_gear%29

    # General
    # https://danbooru.donmai.us/posts?tags=yuri+rating:general+-meme
    # https://danbooru.donmai.us/posts?tags=maid+-furry+rating%3Ag
    # https://danbooru.donmai.us/posts?tags=maid
    # https://danbooru.donmai.us/posts?tags=kimono

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
  '';
  dlDirectory = "/var/gallery-dl";
  configFile = pkgs.writeText "gallery-dl.conf" ''
    {
      "downloader": {
        "mtime": true,
        "rate": "2M",
        "adjust-extensions": true
      }
    }
  '';
in {
  systemd = {
    timers = {
      "gallery-dl-process" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
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
          ${pkgs.gallery-dl}/bin/gallery-dl \
            --config "${configFile}" \
            --input-file "${pages}" \
            --destination "${dlDirectory}" \
            --download-archive "${dlDirectory}/archive.db"
          exit 0;
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
}
