# Maus's NixOS definitions


My deployment is handled via Colmena.
```bash
# If building on Violet
colmana apply --on @default --no-build-target
# otherwise
colmana apply --on @default
```

## Notes

- Unstable is pulled in via `unstablePkgs` in [flake.nix](./flake.nix), and shoved into Colmena's `colmenaConfiguration.meta.specialArgs` object.

    To use the unstable packages, just update the arguments of the file with `unstablePkgs` and then `unstablePkgs.$packageName`.

- Violet is kinda a shit-show, one day I'll either rebuild it and separate out the services into their own containers/VMs or I guess cry (Most likely cry).

- Violet's network config is odd. There are two WANs, `eno1` is the default gateway while `enp68s0`'s metric makes it a second one. The reason behind this is
    
    A) Automatic failover of primary internet
    
    B) Torrenting

    `enp68s0` is connected to my T-Mobile home internet gateway and sits behind a CNAT so have fun finding me.

    Sadly the primary internet doesn't support IPv6, so it's disabled on both interfaces, mainly so I don't have to fuck with route weights.

- Violet has the UPS monitoring on it, uh don't forget that, it will just power off if that cable is missing.

## TODOs

[ ] Fix ACME on all hosts, make them use PDNS API.

[ ] Fix the damned systemd-networkd-wait-online.service, god damn systemd.

[ ] At some point install a GPU in violet, or build up another computer to host Jellyfin and ollama.