# GPU load testing. p15v only (pairs with tools/gpu-monitor.nix).
#
# Which GPU gets the load (verified 2026-10-19 on p15v):
#   OpenGL: PRIME render offload. Plain commands run on the AMD 680M iGPU
#     (the display GPU); `nvidia-offload <cmd>` runs on the RTX A2000
#     (glmark2 then reports GL_RENDERER "NVIDIA RTX A2000").
#   Vulkan: nvidia-offload's __VK_LAYER_NV_optimus does NOT work here — furmark
#     and vkmark still pick RADV. Select the driver via the loader instead:
#       VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
#       VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json
#     With one ICD visible, device/--gpu-index 0 is unambiguous. (FurMark's own
#     --gpu-index without the filter is 0 = AMD, 1 = NVIDIA on this machine.)
#
# Tools:
#   furmark   (unfree 2.x, `furmark` CLI + FurMark_GUI) — the heavy one:
#             furmark-gl / furmark-vk stress demos, --max-time, --benchmark.
#   glmark2   OpenGL benchmark (--off-screen works without a window).
#   vkmark    Vulkan benchmark (prints "Device Name" = the GPU it picked).
#   stress-ng --gpu N --gpu-devnode /dev/dri/renderD128: headless EGL/GLES
#             load. AMD only: on the nvidia node (renderD129) the stressor is
#             skipped (no GBM/EGL there without a display), tested 2026-10-19.
#   gpu-stress  helper below: `gpu-stress nvidia|amd [seconds] [gl|vk]`.
#
# Watch the load from a second terminal: nvtop, gpustat -i 1, nvidia-smi -l 1.
# gpu-burn (CUDA) is marked broken in the pinned nixpkgs, hence FurMark.
# FurMark 2.10.2 segfaults on exit (after the test has completed) when run
# with --disable-traces or --disable-logfile, so the helper does not pass
# them; --no-gpumon and --print-render-speed are fine. Its log lands in
# /tmp/furmark-furmark.log.
{ pkgs, ... }:

let
  gpu-stress = pkgs.writeShellApplication {
    name = "gpu-stress";
    runtimeInputs = [ pkgs.furmark ];
    text = ''
      usage() {
        echo "usage: gpu-stress <nvidia|amd> [seconds] [gl|vk]" >&2
        echo "  FurMark stress test, 1080p windowed. Default 60 s, OpenGL." >&2
        echo "  Monitor from another terminal: nvtop | gpustat -i 1 | nvidia-smi -l 1" >&2
        exit 2
      }
      [ $# -ge 1 ] || usage
      target=$1
      secs=''${2:-60}
      api=''${3:-gl}
      case "$api" in gl|vk) ;; *) usage ;; esac
      icd=/run/opengl-driver/share/vulkan/icd.d
      case "$target" in
        nvidia) run=(nvidia-offload env "VK_DRIVER_FILES=$icd/nvidia_icd.json") ;;
        amd)    run=(env "VK_DRIVER_FILES=$icd/radeon_icd.x86_64.json") ;;
        *)      usage ;;
      esac
      echo "FurMark furmark-$api on $target for $secs s (window may take a few seconds to open)"
      exec "''${run[@]}" furmark \
        --demo "furmark-$api" --gpu-index 0 \
        --width 1920 --height 1080 --vsync 0 \
        --max-time "$secs" \
        --no-score-box --print-render-speed
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    furmark
    glmark2
    vkmark
    stress-ng
    gpu-stress
  ];
}
