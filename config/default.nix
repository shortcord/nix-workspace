{
  sshkeys = {
    users = {
      short = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAXRx3C0/Rjiz5mpqX/Iygkr1wOTG1fw6Am9zKpZUr1 short@dellmaus"
      ];
      deployment = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzNDt0mA8dV9l5A/1tIgLVBf6ynUjjZN0Dckvs3kRIG deployment@gitlab.shortcord.com"
      ];
    };
    hosts = {
      general = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKb0PHLj1RU6PPyYCZWXzVu5gXvAFSgh4SIuhMX/PJ3/ violet.lab.shortcord.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ82K8WXoxEZMyU2VolrWvLZMVw1lR+kAvIyfMqwOxlX ns2.owo.systems"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7tbNsAdbSQXOTNpGKKN3mCSIUGn+hhaAqPzA7gh/Hj storage.owo.systems"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqzy6mgAsJLPsYnYb6sWBvsmZKF8QG7lLE3A/yE55G7 vm01.hetzner.owo.systems"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4tWdXuPUVt2Yv/cGig8Hilm/NZgpsqH1VbKYpOvnwh lilac.lab.shortcord.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMYLWI4ixfYTbbGymECI2zKPsXPzjoJYDPcb/8R4ptX+ matrix.mousetail.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBuhG34gZHiHgpE4rz7sdEZHIuI2154nTK3TOufUkBxA keycloak.lab.shortcord.com"
      ];
    };
  };
  wireguard = {
    "router.cloud.shortcord.com" = {
      publicKey = "ePYkBTYZaul66VdGLG70IZcCvIaZ7aSeRrkb+hskhiQ=";
      ipAddresses = [ ];
    };
    "ns2.owo.systems" = {
      publicKey = "2a8w4y36L4hiG2ijQKZOfKTar28A4SPtupZnTXVUrTI=";
      ipAddresses = [ "10.7.210.1/32" ];
    };
    "vm-01.hetzner.owo.systems" = {
      publicKey = "x8o7GM5Fk1EYZK9Mgx4/DIt7DxAygvKg310G6+VHhUs=";
      ipAddresses = [ "10.7.210.2/32" ];
    };
    "storage.owo.systems" = { 
      publicKey = "";
      ipAddresses = [ ];
    };
    "lilac.lab.shortcord.com" = {
      publicKey = "iCm6s21gpwlvaVoBYw0Wyaa39q/REIa+aTFXvkBFYEQ=";
      ipAddresses = [ "10.7.210.3/32" ];
    };
    "violet.lab.shortcord.com" = {
      publicKey = "";
      ipAddresses = [ ];
    };
  };
}
