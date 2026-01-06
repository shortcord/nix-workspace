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

    services.nfs.server = {
        enable = true;
        nproc = 128;
        exports = ''
            /var/lib/vmdata 10.65.0.0/30(rw,no_root_squash) 10.66.0.0/30(rw,no_root_squash,async,rw,no_subtree_check)
            /var/jellyfin 100.64.0.0/24(rw,async,rw,no_subtree_check,all_squash,anonuid=990,anongid=983)
        '';
    };
}
