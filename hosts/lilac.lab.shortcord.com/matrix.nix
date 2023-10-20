{ pkgs, config, ... }:
{
    services = {
        matrix-synapse = {
            enable = false;
            settings = {};
        };
    };
}