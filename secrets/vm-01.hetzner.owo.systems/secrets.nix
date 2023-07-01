let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaxLI7oCJcUxfjGXXgs9YI7DimlFbtWE+R22jDF6Zxl short@maus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUi5rrB0okX4gQUsivnujVY+0ggin5zKTJMP7ynwKLU short@surface"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWfoWfo/L6yoIwCbnV7IwfsSFrrrnt6cQpoX60YDaQ0 short@mauspad"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAXRx3C0/Rjiz5mpqX/Iygkr1wOTG1fw6Am9zKpZUr1 short@dellmaus"
  ];
  servers = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqzy6mgAsJLPsYnYb6sWBvsmZKF8QG7lLE3A/yE55G7"
  ];
in { "prometheusBasicAuthPassword.age".publicKeys = users ++ servers; }
