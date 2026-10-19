# Local LLM toolbox: runtimes, GUIs, CLIs and model-inspection tools.
# Enable per host by importing it from hosts/<name>/configuration.nix.
#
# Sizing on p15v (RTX A2000 Laptop, 4 GB VRAM, 30 GB RAM): a 3-4B model at
# Q4 fits entirely in VRAM; 7-8B runs with partial offload (ollama splits
# automatically, `ollama ps` shows the CPU/GPU ratio; llama.cpp via -ngl N);
# anything bigger runs from RAM on the CPU. Watch it with nvtop / gpustat
# (tools/gpu-monitor.nix).
#
# CUDA variants (ollama-cuda, llama-cpp with cudaSupport) are NOT on
# cache.nixos.org, so the first build compiles them locally (long). The NixOS
# wiki page "Cuda" documents a community binary cache that carries them;
# whether to trust it is a per-machine decision, so it is not configured here.
#
# Not enabled here on purpose:
#   open-webui  browser chat UI over ollama: services.open-webui.enable = true
#               (unfree, ~2.7 GB closure). Jan/LM Studio cover the GUI need.
#   vllm        was listed before; the nixpkgs build is CPU-only without
#               nixpkgs.config.cudaSupport, pulls a 3 GB closure and wants far
#               more than 4 GB VRAM to be useful. Re-add when there is a GPU
#               for it.
#   torch+CUDA  python3Packages.torch with CUDA is a multi-hour local build;
#               add on demand.
#   l14 (AMD only): ollama runs on the CPU there. pkgs.ollama-rocm plus
#               services.ollama.rocmOverrideGfx would be the iGPU route, and
#               pkgs.ollama-vulkan the driver-agnostic one.
{ config, pkgs, ... }:

let
  hasNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;
  llama-cpp =
    if hasNvidia
    then pkgs.llama-cpp.override { cudaSupport = true; }
    else pkgs.llama-cpp;
in
{
  # ollama: systemd service on 127.0.0.1:11434, models under
  # /var/lib/ollama/models, CLI in PATH (`ollama run qwen2.5:3b`, `ollama ps`).
  # It is the OpenAI-compatible backend for oterm, aichat and Jan below.
  services.ollama = {
    enable = true;
    package = if hasNvidia then pkgs.ollama-cuda else pkgs.ollama; # CPU build otherwise
  };

  environment.systemPackages = with pkgs; [
    # Runtimes
    llama-cpp   # llama-server, llama-cli, llama-bench, llama-perplexity,
                # llama-quantize, llama-imatrix, llama-gguf-split, llama-tokenize
    koboldcpp   # single-binary GGUF runner with web UI, Vulkan backend

    # GUIs (AppImage packages, each keeps its own model directory)
    lmstudio    # unfree; ~/.lmstudio, model browser + local OpenAI server
    jan         # open source; bundled llama.cpp, can also point at ollama

    # Terminal clients
    oterm       # TUI chat over ollama
    aichat      # CLI/REPL for ollama, llama-server and any OpenAI-style API

    # Model plumbing
    (python3.withPackages (ps: with ps; [
      huggingface-hub   # `hf download <repo> <file.gguf>` fetches models from HF
      gguf              # gguf-dump / gguf-set-metadata: inspect and edit GGUF files
      llama-cpp-python  # CPU build of the Python bindings for scripting
    ]))
  ];
}
