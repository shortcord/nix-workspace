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

## Building Proxmox VMA or LXC

[nixos-generators](https://github.com/nix-community/nixos-generators) is responsible for building the VMAs and LXC tarballs that Proxmox expects.

You can generate a VMA of any host defined in [`flake.nix`](./flake.nix) who's config passes `!config.boot.isContainer`; AKA if it's not a container.

You can also generate a LXC tarball (proxmox flavour) of any host defined in [`flake.nix`](./flake.nix) who's config passes `config.boot.isContainer`; AKA if it's a container.

You can view the package names via `nix flake show`. 

An example for LXC would be `nix build .#lxc-gitlab-rack02-shortcord-com`, one for VMAs would be `nix build .#vm-violet-lab-shortcord-com`.

## Caveats

### Secrets
Secrets are deployed via [agenix](https://github.com/ryantm/agenix) (or more precisely [ragenix](https://github.com/yaxitech/ragenix)), host keys are defined in [scConfig](./config/default.nix). This means that you'd need to first boot a host to get the hostkey then add it to [scConfig](./config/default.nix), commit, and redeploy for secrets to be decrypted.

The exception to this are containers, as it is expected that the Proxmox host has a known SSH key bind-mounted into the container at `/agenix/shared-container-key` (see [`container-base.nix`](./containers/general/container-base.nix)). Tooling that automates this will be created soon.


## Notes

- Unstable is pulled in via `unstablePkgs` in [flake.nix](./flake.nix), and shoved into Colmena's `colmenaConfiguration.meta.specialArgs` object.

    To use the unstable packages, just update the arguments of the file with `unstablePkgs` and then `unstablePkgs.$packageName`.

- Violet is kinda a shit-show, one day I'll either rebuild it and separate out the services into their own containers/VMs or I guess cry (Most likely cry).

- Violet has the UPS monitoring on it, uh don't forget that, it will just power off if that cable is missing.
    - Violet currently only monitors the one UPS, will need to get another USB Type-A cable for the other one.

- Violet also has a Nvidia GPU (RTX 2060) installed, it's also using the propiatary driver instead due to my want for better performance while decoding (that and the 20xx family is still semi broken).

## TODOs

- [x] Fix ACME on all hosts, make them use PDNS API.
- [x] Fix the damned systemd-networkd-wait-online.service, god damn systemd.
- [x] At some point install a GPU in violet, or build up another computer to host Jellyfin and ollama.
- [ ] Go through all the hosts and either update or remove `permittedInsecurePackages` entries
- [ ] Go through all the hosts and remove `nixpkgs.config.allowUnfree = true;` since we are setting that in `flake.nix`
    - We should use `nixpkgs.config.allowUnfreePredicate` instead of blindly allowing all packages
- [ ] Fix `evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'`
    - Pretty sure it's talking about the entries in `flake.nix`; haven't looked into it yet.