#!/usr/bin/env bash
set -e

if [[ -z "${1}" ]]; then
    echo "gimme vm hostname"
    exit 1
fi

nix build ".#vm.vm-${1}" || ( echo "nix broke :("; exit 1; )

rsync -P --copy-links result/vzdump-*.vma.zst root@pve.owo.solutions:"/var/lib/vz/dump/vzdump-nixos-${1}.vma.zst" || ( echo "rsync broke :(("; exit 1; )
