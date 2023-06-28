let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
  ];
  servers = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKb0PHLj1RU6PPyYCZWXzVu5gXvAFSgh4SIuhMX/PJ3/"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ82K8WXoxEZMyU2VolrWvLZMVw1lR+kAvIyfMqwOxlX"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7tbNsAdbSQXOTNpGKKN3mCSIUGn+hhaAqPzA7gh/Hj"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqzy6mgAsJLPsYnYb6sWBvsmZKF8QG7lLE3A/yE55G7"
  ];
in { 
  "distributedUserSSHKey.age".publicKeys = users ++ servers;
 }
