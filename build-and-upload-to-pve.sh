#!/usr/bin/env bash
set -e

if [[ -z "${1}" ]]; then
    echo "gimme vm hostname"
    exit 1
fi

if [[ -z "${2}" ]]; then
    echo "gimme vm id"
    exit 1
fi

if [[ -z "${3}" ]]; then
    echo "gimme proxmox host"
    exit 1
fi

nix build ".#vm.${1}" || ( echo "nix broke :("; exit 1; )

rsync -P --copy-links result/nixos.img root@"${3}":"/tmp/nixos.img" || ( echo "rsync broke :(("; exit 1; )

ssh root@"${3}" -- qm disk import "${2}" /tmp/nixos.img tank
