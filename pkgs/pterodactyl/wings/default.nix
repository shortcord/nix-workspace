{ lib
, stdenv
, fetchurl
, php
, pkgs
}:
stdenv.mkDerivation rec {
  name = "pterodactylWings";
  version = "1.11.7";

  dontUnpack = true;

  binary = fetchurl {
    url = "https://github.com/pterodactyl/wings/releases/download/v${version}/wings_linux_amd64";
    hash = "sha256-pb9BKeOARzFoQVJC8hgDFMXzrPHjJKGYd9pKSXXwlWg=";
  };

  unpackPhase = "";

  installPhase = ''
    mkdir -p $out/bin
    ls -lah
    cp $binary $out/bin/wings
    chmod +x $out/bin/wings
  '';

  meta = {
    description = "Pterodactyl Wings";
    homepage = "https://github.com/pterodactyl/wings";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shortcord ];
    platforms = [ "x86_64-linux" ];
  };
}