{ name, nodes, pkgs, lib, config, ...  }: {
  virtualisation.oci-containers.containers = {
    "maxscale" = {
      autoStart = true;
      image = "docker.io/mariadb/maxscale:latest";
      volumes = [ "maxscale-config:/var/lib/maxscale/:rw" ];
      ports = [ "3366:3366" "127.0.0.1:8989" ];
    };
  };
}
