{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = false;  # keep the menu bar visible
      AppleShowAllExtensions = true;
      "com.apple.swipescrolldirection" = false;  # turn off "natural" scrolling
    };
    dock = {
      autohide = false;
      show-recents = false;  # no "recent apps" section
      # Exact Dock contents, reset on every rebuild. Finder and Trash are
      # always present and can't be listed or removed.
      persistent-apps = [
        "/Applications/Google Chrome.app"
        "/Applications/Visual Studio Code.app"
        "/System/Applications/Utilities/Terminal.app"
        "/System/Applications/Notes.app"
        "/System/Applications/System Settings.app"
      ];
      # Right side, before Trash (which is always last).
      persistent-others = [
        "/Users/${user}/Downloads"
      ];
    };
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "opencode"     # coding agent CLI (homebrew-core formula, not a cask)
    ];
    casks = [
      "wezterm"
      "claude-code"
      "codex"        # OpenAI's coding agent CLI
      "visual-studio-code"
      "google-chrome"
    ];
    # VS Code extensions are installed from home.nix, not homebrew.vscode:
    # brew bundle's VS Code support reported the editor as missing even with
    # `code` on PATH, which failed every rebuild.
  };

  # nix-darwin has no wallpaper option, so set it on every activation.
  # Runs as the user because the desktop picture is a per-user setting.
  # The first run may prompt to allow the terminal to control System Events.
  system.activationScripts.postActivation.text = ''
    sudo -u ${user} osascript -e 'tell application "System Events" to tell every desktop to set picture to "/Users/${user}/.dotfiles/wallpapers/JourneysEnd-Night-PC-Wallpaper.png"' || true
  '';
}
