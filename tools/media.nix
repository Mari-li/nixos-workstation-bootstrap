# Zenbook's copy of tools/multimedia.nix without Kdenlive.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    spotify
    vlc
  ];
}
