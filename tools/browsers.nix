# Zenbook's copy of tools/www.nix: Google Chrome and Firefox (no Chromium).
{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    google-chrome
  ];
}
