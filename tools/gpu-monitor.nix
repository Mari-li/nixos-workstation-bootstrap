# GPU monitoring. p15v only: gpustat talks to NVML, so it needs the NVIDIA
# driver; nvtop also shows the AMD iGPU, so "full" (all backends) is used
# instead of nvtopPackages.nvidia. nvidia-smi is not listed here on purpose:
# it ships with hardware.nvidia.package and is already in the system path.
#
# NOTE: top-level pkgs.gpustat is a different program (arduano/gpustat, a
# Rust/GUI app that hangs without a display). The classic one-line NVIDIA
# summary (wookayin/gpustat, `gpustat --watch`) is python3Packages.gpustat.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nvtopPackages.full      # htop-style TUI, AMD + NVIDIA, per-process GPU use
    python3Packages.gpustat # `gpustat -cp`, `gpustat --watch`: NVML summary
  ];
}
