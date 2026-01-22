{ lib, ... }:
let
  short = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqcmQeDrJdqJFCd25dJzW4YB298X98ls9v24LCjzne2 Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINX7oG0R0G46LogXQ6/cAHK6FU4RLSKBI/B+VMbfnZvw Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+WQNAEcOMKpWFofZVJGe5M0gr5dyDAMBQhmev8D/VC Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZ74egcjLnliszE3b0s7DBY8y/1yF4ZdEPlRpNHbEPw Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOy6OTnx5c72jtkGQo4LFxrpUraUF52C541lrqltSvrd Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPrDWhYX7ALenoIyMYh6MzYBGbbgSLSWbz9EfzEkxo0k Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAXRx3C0/Rjiz5mpqX/Iygkr1wOTG1fw6Am9zKpZUr1 Maus Creacher (gitlab.shortcord.com)"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 Maus Creacher (gitlab.shortcord.com)"
  ];

  hosts = {
      ns2 = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ82K8WXoxEZMyU2VolrWvLZMVw1lR+kAvIyfMqwOxlX ns2.owo.systems" ];
      violet = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKb0PHLj1RU6PPyYCZWXzVu5gXvAFSgh4SIuhMX/PJ3/ violet.lab.shortcord.com" ];
      storage = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7tbNsAdbSQXOTNpGKKN3mCSIUGn+hhaAqPzA7gh/Hj storage.owo.systems" ];
      vm-01 = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqzy6mgAsJLPsYnYb6sWBvsmZKF8QG7lLE3A/yE55G7 vm01.hetzner.owo.systems" ];
      lilac = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4tWdXuPUVt2Yv/cGig8Hilm/NZgpsqH1VbKYpOvnwh lilac.lab.shortcord.com" ];
      keycloak = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHw2ZJN9Mk/MILgpdDQ3a3/o7SCPHvbT/iaWWMnMWM3O keycloak.owo.solutions" ];
      lavender = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJJkiqaqs67EEzd73X9RQu6vvya64EgtDQBGf4vQ5LN lavender.lab.shortcord.com" ];
      
      # Pre-generated shared key for LXC containers on labmox.ts.shortcord.com
      labmox = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMMwywWvRbQSKYObyhQc+mgV2SPwbNuRsosoFgvTTvM root@labmox.ts.shortcord.com" ];
    };

  _flattenedHosts = lib.flatten (lib.attrValues (hosts));

  allKeys = _flattenedHosts ++ short;
  allHosts = _flattenedHosts ++ short;

  # Helper fnc to grab just one node's hostkey
  keyForHost = nodeName:
    let shortName = builtins.head (lib.splitString "." nodeName);
    #                                                   I still need my own keys to edit the secret
    in assert hosts ? ${shortName}; (hosts.${shortName} ++ short);

in {
  inherit keyForHost;
  sshkeys = {
    inherit allKeys allHosts hosts;
    users = {
      inherit short;
      deployment = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzNDt0mA8dV9l5A/1tIgLVBf6ynUjjZN0Dckvs3kRIG deployment@gitlab.shortcord.com"
      ];
    };
  };
}
