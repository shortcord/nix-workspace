{ config, ... }: {

nixpkgs.config = {
  allowUnfree = true;
  nvidia.acceptLicense = true;
};

hardware = {
    graphics.enable = true;
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidia_x11_legacy470;
      videoAcceleration = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
    };
    nvidia-container-toolkit.enable = true;
  };
  services.xserver = {
    enable = false;
    videoDrivers = [ "nvidia" ];
  };
}