{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    zoom-us
    slack
    telegram-desktop
  ];
}
