#! /usr/bin/env nix-shell
#! nix-shell -i bash -p colmena bash
set -e
colmena exec -- nix-collect-garbage