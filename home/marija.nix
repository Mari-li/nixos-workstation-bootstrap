{ pkgs, lib, inputs, ... }:

{
  home = {
    stateVersion = "26.05";
    packages = [
      pkgs.nixd
    ];
  };

  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  programs.bash.enable = true;

  # Overrides the system-wide identity set in tools/common.nix.
  programs.git = {
    enable = true;
    settings.user = {
      name = "Marija Liscova";
      email = "marija.liscova@gmail.com";
    };
  };

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = ["google-chrome.desktop"];
        "x-scheme-handler/http" = ["google-chrome.desktop"];
        "x-scheme-handler/https" = ["google-chrome.desktop"];
      };
    };
  };

  /**
   * Plasma is left on its defaults; copy pieces from home/eg.nix
   * (panel, shortcuts, theme) when you want them.
   * https://github.com/nix-community/plasma-manager
   */
  programs.plasma = {
    enable = true;

    input.keyboard.switchingPolicy = "window";
  };
}
