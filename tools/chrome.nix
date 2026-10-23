# Zenbook's copy of tools/www.nix: Google Chrome only.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome
  ];
}
