# Zenbook's slimmed-down copy of tools/common.nix: no QGIS, no hard-coded
# git identity (set per user in home/marija.nix), nano as default editor.
{ pkgs, ... }:

{
  programs.git.enable = true;
  programs.lazygit.enable = true;

  programs.nano.enable = true;
  programs.vim.enable = true;
  environment.variables.EDITOR = "nano";
  environment.variables.VISUAL = "nano";

  programs.screen.enable = true;

  # https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    htop
    mc
    nmap
    wget
    appimage-run
    openssl_3_5
    dig
    unixtools.netstat
    lsyncd
    usbutils
    filezilla
    keepassxc
    pciutils
    pavucontrol
    obsidian
    gh
  ];
}
