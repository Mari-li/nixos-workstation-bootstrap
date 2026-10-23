# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal NixOS flake configuring three laptops: two Lenovo ThinkPads (`l14` and `p15v`) and an ASUS Zenbook S16 UM5606GA (`zenbook`). It lives at `/etc/nixos` on the target machine. There is no application code, no tests, and no build step other than `nixos-rebuild`/`nixos-install`.

## Commands

```bash
# Rebuild the running system after editing config (run on the target host)
nixos-rebuild switch --flake .#l14      # or .#p15v

# zenbook: the repo is owned by marija, so build as that user and use sudo
# only to activate. sudo needs a real terminal for the password, so the user
# runs this in Konsole; `nixos-rebuild build` works without it.
nixos-rebuild switch --sudo --flake /etc/nixos#zenbook

# Update all flake inputs, then rebuild
nix flake update
nixos-rebuild switch --flake .#<host>

# Fresh install (from the NixOS installer, after partitioning — see README.md)
nixos-install --flake .#<host> --root /mnt

# Regenerate PCI bus IDs for the p15v dual-GPU PRIME setup (run on p15v)
nix shell nixpkgs#pciutils -c bash ./detect-gpu-bus-ids.sh
```

There is no linter. To sanity-check a change without switching, use `nixos-rebuild build --flake .#<host>` or `nix flake check`.

## Architecture

`flake.nix` defines three `nixosConfigurations` (`l14`, `p15v`, `zenbook`). All wire in `home-manager` as a NixOS module (users.eg → `home/eg.nix`; `p15v` additionally imports `home/p15v-power.nix`, the no-suspend PowerDevil policy of the freeze trial described in `hosts/p15v/FREEZE-PLAN.md`) and pass `inputs` plus a locally-defined `qidi-studio` AppImage package through `extraSpecialArgs`. `zenbook` uses users.marija → `home/marija.nix` and passes only `inputs`. Adding another host means adding another entry here that imports its own `hosts/<name>/configuration.nix`.

Configuration is composed by import, split into four layers:

- **`hosts/<name>/configuration.nix`** — the only per-host file and the entry point for that host. Holds hostname, hardware/kernel/GPU specifics, power management, the user account, and the `imports` list selecting which shared modules to activate. `l14` (AMD iGPU only) and `p15v` (AMD 680M iGPU + NVIDIA RTX A2000 PRIME offload) differ mainly in GPU and kernel-param setup. `zenbook` (Ryzen AI, Radeon iGPU, 3K OLED, LUKS + btrfs) started as a copy of `l14`: power-profiles-daemon instead of tlp, s2idle only, and `amdgpu.dcdebugmask=0x410` (PSR + Panel Replay off), without which the OLED panel stays dark once amdgpu loads. It imports `tools/essentials.nix`, a slimmed copy of `tools/common.nix`.
- **`general/`** — cross-cutting system concerns (`i18n`, `network` with NetworkManager + L2TP VPN, `pipewire` audio).
- **`workspace/kde.nix`** — the KDE Plasma 6 + Wayland desktop, fonts, xdg portals.
- **`tools/*.nix`** — one file per capability area (`docker`, `python`, `php85`, `3d`, `kvm`, `multimedia`, `android` = distrobox, `agentic` = claude-code, etc.). Each is a self-contained module. Enable a capability on a host by adding its import to that host's `imports` list; several are commented out per-host (e.g. `ai`). Android development runs in a Distrobox container rather than Nix: `tools/android.nix` provides distrobox + rootless podman (pinned via `/etc/distrobox/distrobox.conf`, since docker is also installed), and `android-dev/` holds the container manifest (`distrobox.ini`) and `install-android-studio.sh`, which installs Studio into the shared `$HOME` and exports the launcher and adb/fastboot to the host. The host deliberately has no `android-tools`, so only one adb server/version exists.

`home/marija.nix` is zenbook's much smaller home-manager config: git identity, `programs.gh` with its git credential helper (the git config is a read-only home-manager file, so `gh auth setup-git` cannot write it), and `xdg.mimeApps` with `mimeapps.list` set to `force = true`. Apps such as JetBrains Toolbox and Claude Code rewrite that file; without `force` a leftover `mimeapps.list.backup` aborts the whole home-manager activation. Declare URL handlers in `defaultApplications` instead.

`home/eg.nix` is home-manager user config: heavy per-app setup for the Zed editor, KDE Plasma via `plasma-manager`, atuin, and a user-level Dropbox systemd service.

## Key conventions

- **`hardware-configuration.nix` and `gpu-bus-ids.nix` are gitignored** (see `.gitignore`) because they are machine-generated and machine-specific. `l14`/`p15v` import the copy at the repo root; during install it must be force-added (`git add -f`) so the flake can see it, or generated on the target. `zenbook` instead commits its file at `hosts/zenbook/hardware-configuration.nix` (imported as `./hardware-configuration.nix`); the ignore pattern matches at any depth, so a new copy there needs `git add -f` once. `p15v` has an `assertion` that fails the build if `gpu-bus-ids.nix` holds empty or identical PCI IDs — regenerate it with `detect-gpu-bus-ids.sh` on that laptop (the script matches GPUs by PCI vendor ID, `1002`/`10de`).
- All hosts track `nixos-unstable` (see `flake.nix`; a commented-out `nixos-26.05` pin is kept there), enable flakes + `allowUnfree`, cap boot generations at 10, and garbage-collect weekly.
- Shared modules take only `{ pkgs, ... }` (plus `lib`/`config` as needed) and add to `environment.systemPackages` or enable services — keep new capabilities as new `tools/*.nix` modules rather than expanding host files.
- The user is `eg` on `l14`/`p15v` and `marija` on `zenbook`; `system.stateVersion` is `26.05` and must not be bumped just because the channel moved.
