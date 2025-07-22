{ lib, pkgs, config, name, ... }: {
    fileSystems = {
        "/var/lib/vmdata" = {
            device = "/dev/disk/by-uuid/f6dda70e-3919-40df-adff-55b4947a7576";
            fsType = "btrfs";
            options = [
                "noatime"
                "degraded"
                "compress=zstd"
                "discard=async"
                "space_cache=v2"
                "subvolid=1508"
            ];
        };
    };

    services.nfs = {
        enable = true;
        exports = ''
            /var/lib/vmdata 10.65.0.0/30(rw)
        '';
    };
}
