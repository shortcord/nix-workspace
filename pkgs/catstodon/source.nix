# This file was generated by pkgs.mastodon.updateScript.
{ fetchgit, applyPatches }: let
  src = fetchgit {
    url = "https://github.com/CatCatNya/catstodon.git";
    rev = "0527458f381a1c7c934a7d2f9ce74b89b7ef855d";
    sha256 = "126fba5z8mxx1z2in3v2cah8mzqzwfmf5wkshrdwia0qx2iyimkn";
  };
in applyPatches {
  inherit src;
  patches = [];
}
