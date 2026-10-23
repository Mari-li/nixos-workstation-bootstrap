{ pkgs, lib, ... }:

# Target hardware:
#   ASUS Zenbook S16 UM5606GA
#   Processor AMD Ryzen AI (Krackan/Strix Point), integrated Radeon graphics
#   Display 16" 3K OLED
#   Memory 32GB
#   Storage 1TB NVMe (954GB usable)
#   BIOS UM5606GA.305 (2026-02-25), American Megatrends
#
# Started as a copy of hosts/l14 (also AMD iGPU only). Differences from l14:
#   - no ThinkPad bits (tlp, fprintd); power-profiles-daemon instead of tlp,
#     which is what AMD recommends for amd-pstate on Ryzen AI
#   - no mem_sleep_default=deep: Ryzen AI laptops only support s2idle
#   - VirtualBox instead of libvirt/KVM (the existing VMs are VirtualBox ones)

{
  imports = [
    ../../hardware-configuration.nix

    ../../general/i18n.nix
    ../../general/pipewire.nix
    ../../general/network.nix

    ../../workspace/kde.nix

    ../../tools/essentials.nix
    ../../tools/docker.nix
    ../../tools/browsers.nix
    ../../tools/development-web.nix
    ../../tools/php85.nix
    ../../tools/libreoffice.nix
    ../../tools/media.nix
    ../../tools/frontend.nix
    ../../tools/vscode.nix
    ../../tools/communication.nix
    ../../tools/printing.nix

    ../../tools/kvm.nix
    ../../tools/vagrant.nix

    ../../tools/agentic.nix

    # Fallback if a VM has to stay on VirtualBox. Its kernel module is built
    # against linuxPackages_latest and occasionally lags behind new kernels.
    #../../tools/virtualbox.nix
  ];

  # Use latest kernel: Ryzen AI and the MediaTek Wi-Fi 7 card need it.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "zenbook";

  # Firmware / microcode
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  # Partition labelled "swap" by `mkswap -L swap` during install (see README).
  swapDevices = [ {
    device = "/dev/disk/by-label/swap";
  } ];

  services.xserver.enable = false;

  # Wayland + sddm
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # (OpenGL/Vulkan/VA-API)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libva
      libva-utils
      libva-vdpau-driver
      libvdpau-va-gl
      vulkan-loader
      vulkan-validation-layers
    ];
  };

  environment.systemPackages = with pkgs; [
    mesa
    mesa-demos
    vulkan-tools
    wayland
    wayland-utils
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # for Electron/Chromium
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Firmware updates (BIOS/EC via LVFS where ASUS publishes them)
  services.fwupd.enable = true;
  services.acpid.enable = true;

  # Power: power-profiles-daemon drives amd-pstate EPP; Plasma's battery
  # applet switches between power-saver / balanced / performance.
  services.power-profiles-daemon.enable = true;

  # Enable experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
  };

  environment.variables = {
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # Cap old NixOS generations
  boot.loader.systemd-boot.configurationLimit = 10; # only 10 generations are kept
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Set the password before the first reboot:
  #   nixos-enter --root /mnt -c 'passwd marija'
  users.users.marija = {
    isNormalUser = true;
    description = "Marija Liscova";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "kvm"
      "lp"
      "scanner"
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  # Suspend first then hibernate when closing the lid; hibernate on power
  # button, poweroff on long press. Inside a Plasma session PowerDevil
  # overrides these; logind only governs the no-session case (SDDM, TTY).
  # Hibernation needs swap >= RAM.
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  systemd.sleep.settings = {
    Sleep = {
      HibernateDelaySec = "30m";
    };
  };

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
