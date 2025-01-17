# Maus's NixOS definitions


My deployment is handled via Colmena and `nixos-upgrade.service` pulling from `main`.
```bash
# Enter devshell
nix develop
# If building on Violet
colmana apply --on @default
# otherwise
colmana apply --on @default --build-on-target
```

## Building Proxmox VMAs

[nixos-generators](https://github.com/nix-community/nixos-generators) is responsible for building the VMAs that Proxmox expects, currently it will generate packages with `vm-` prefix and hostname, for example `nix build .#vm-gitlab` will build the VMA for the Gitlab container and shit out a result file.

This piggybacks on how I tell colmena to deploy only to physical hosts and not containers, however it means *any* container could be build as a VM. Maybe neat for migrations but not ideal right now.

The major benefit of this is that all the defaults defined for the colmena hive propagate down to the built VM, meaning I can define a machine in nix, shit out a VMA, upload, and boot without having to even ssh into an install os. This makes building up a new machine painless.

Eh it works, fuck it.

## Notes

- Unstable is pulled in via `unstablePkgs` in [flake.nix](./flake.nix), and shoved into Colmena's `colmenaConfiguration.meta.specialArgs` object.

    To use the unstable packages, just update the arguments of the file with `unstablePkgs` and then `unstablePkgs.$packageName`.

- Violet is kinda a shit-show, one day I'll either rebuild it and separate out the services into their own containers/VMs or I guess cry (Most likely cry).

- ~~Violet has the UPS monitoring on it, uh don't forget that, it will just power off if that cable is missing.~~ Disabled until I move the rack, again.

- ~~NS2's headscale instance is kind of a mess right now, using stable's config generation with unstable's package means duplicated settings and stuff. Currently it "works" but is really finicky, I should really just pull that out into it's own flake that does everything correctly.~~ Should be fine now with 24.11 (fingers crossed).


## TODOs

[ ] Fix ACME on all hosts, make them use PDNS API.

[x] Fix the damned systemd-networkd-wait-online.service, god damn systemd.

[ ] At some point install a GPU in violet, or build up another computer to host Jellyfin and ollama.