
{ unstablePkgs, ... }: {
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    package = unstablePkgs.ollama-cuda;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "128000";
      OLLAMA_KV_CACHE_TYPE="q4_0";
      OLLAMA_FLASH_ATTENTION="1";
      OLLAMA_NUM_PARALLEL="1";
      OLLAMA_KEEP_ALIVE="-1";
    };
  };
}
