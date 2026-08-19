{ config, lib, nodes, name, pkgs, ... }:
let
  cfg = config.sc.hybridMesh;

  # Collect every mesh member's identity from the colmena `nodes` specialArg.
  members = lib.mapAttrsToList
    (nodeName: node:
      let mesh = node.config.sc.hybridMesh;
      in { inherit (mesh) ipv4 publicKey endpoint isHub; })
    (lib.filterAttrs (_: node: node.config.sc.hybridMesh.ipv4 != null) nodes);

  # The hub is the node with isHub = true. Spokes peer only to it.
  hub = lib.findFirst (m: m.isHub) null members;

  # Peers as seen from this host.
  peers = if cfg.isHub then
    # Hub peers with every other member.
    lib.filter (m: m.publicKey != cfg.publicKey) members
  else
    # Spoke peers only with the hub, outbound.
    lib.optional (hub != null) hub;
in {
  options.sc.hybridMesh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the WireGuard hybrid mesh.";
    };
    ipv4 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Mesh address (10.8.210.0/24) for this host, e.g. 10.8.210.1/32.";
    };
    publicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "This host's WireGuard public key.";
    };
    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51821;
      description = "UDP port the mesh interface listens on.";
    };
    endpoint = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Reachable host:port for this member. Null for behind-NAT spokes.";
    };
    isHub = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host is the mesh hub (ns2).";
    };
    mtu = lib.mkOption {
      type = lib.types.int;
      default = 1420;
      description = "MTU of the mesh interface.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.ipv4 != null && cfg.publicKey != null) {
    age.secrets.wgMeshPrivateKey.owner = "root";
    age.secrets.wgMeshPrivateKey.group = "root";

    networking.wireguard = {
      enable = true;
      interfaces.wg-mesh = {
        inherit (cfg) mtu listenPort;
        ips = [ cfg.ipv4 ];
        privateKeyFile = config.age.secrets.wgMeshPrivateKey.path;
        peers = map (m: {
          publicKey = m.publicKey;
          allowedIPs = [ (lib.head (lib.splitString "/" m.ipv4) + "/32") ];
          persistentKeepalive = 25;
          endpoint = m.endpoint;
        }) peers;
      };
    };

    networking.firewall = {
      allowedUDPPorts = [ cfg.listenPort ];
      trustedInterfaces = [ "wg-mesh" ];
    };
  };
}
