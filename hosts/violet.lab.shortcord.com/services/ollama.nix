{ name, config, unstablePkgs, ... }: {
  age.secrets = {
    vllmEnv = {
      file = ../../../secrets/${name}/vllmEnv.age;
    };
  };

  virtualisation = {
    oci-containers = {
      backend = "docker";

      containers = {
        vllm = {
          autoStart = true;
          pull = "always";
          image = "vllm/vllm-openai:latest";
          ports = [
            "11434:8000/tcp"
          ];
          cmd = [
            "--model" "Qwen/Qwen2.5-Coder-3B-Instruct"
            "--dtype" "auto"
            "--gpu-memory-utilization" "0.90"
          ];
          extraOptions = [
            "--device=nvidia.com/gpu=all"
            "--ipc=host"
          ];
          volumes = [
            "/root/.cache/huggingface:/root/.cache/huggingface:rw"
          ];
          environmentFiles = [
            config.age.secrets.vllmEnv.path
          ];
        };
      };
    };
  };
}