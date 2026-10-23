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

  # gh, plus its git credential helper for https://github.com. The git config
  # is a read-only home-manager file, so `gh auth setup-git` can't write it.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = ["google-chrome.desktop"];
        "x-scheme-handler/http" = ["google-chrome.desktop"];
        "x-scheme-handler/https" = ["google-chrome.desktop"];
        "x-scheme-handler/jetbrains" = ["jetbrainsd.desktop"];
        "x-scheme-handler/claude-cli" = ["claude-code-url-handler.desktop"];
      };
    };

    # Apps (JetBrains Toolbox, Claude Code) rewrite mimeapps.list to register
    # their URL handlers, replacing the symlink with a real file. Without force
    # home-manager backs it up, and aborts the whole activation once a
    # mimeapps.list.backup already exists. Handlers belong in the list above.
    configFile."mimeapps.list".force = true;
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
