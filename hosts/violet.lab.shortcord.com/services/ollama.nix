
{ unstablePkgs, ... }: {
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "0.0.0.0";
    package = unstablePkgs.ollama-cuda;
  };
}
