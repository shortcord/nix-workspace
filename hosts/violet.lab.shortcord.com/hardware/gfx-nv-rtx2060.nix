{ ... }: {

hardware = {
    graphics.enable = true;
    nvidia = {
      open = false;
      videoAcceleration = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
    };
  };
  services.xserver = {
    enable = false;
    videoDrivers = [ "nvidia" ];
  };
}