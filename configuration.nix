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
        "/Applications/WezTerm.app"
        "/System/Applications/Utilities/Terminal.app"
        # agent workspaces: firstmate's optional cmux and Orca backends
        "/Applications/cmux.app"
        "/Applications/Orca.app"
        "/Applications/Pi Launcher.app"
        # workflow utilities; the last three also live in the menu bar
        "/Applications/OpenSuperWhisper.app"
        "/Applications/Baby Menu.app"
        "/Applications/Automic Vault.app"
        "/Applications/Tailscale.app"
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
    # Third-party taps for tools with no homebrew-core formula or cask.
    # Homebrew 6+ refuses to load anything from an untrusted third-party tap,
    # so each one is trusted explicitly. Trust covers the whole tap, including
    # future formulae and casks, so only list taps you would install from anyway.
    taps = [
      { name = "kunchenguid/tap"; trusted = true; }  # pi-launcher, baby-menu
      { name = "can1357/tap";     trusted = true; }  # omp (Oh My Pi)
      { name = "stablyai/orca";   trusted = true; }  # Orca
      { name = "automic-vault/isotopes"; trusted = true; }  # Automic Vault
    ];
    brews = [
      "herdr"
      "opencode"          # coding agent CLI (homebrew-core formula, not a cask)
      "node"              # npm host for Pi and the axi CLIs installed from home.nix
      "can1357/tap/omp"   # Oh My Pi, a Pi fork firstmate verifies as a primary harness
      "kimi-code"         # Kimi Code CLI (`kimi`), a firstmate crewmate harness
    ];
    casks = [
      "wezterm"
      "claude-code@latest"  # latest channel; plain `claude-code` lags behind new releases
      "codex"       # OpenAI's coding agent CLI
      "grok-build"   # xAI's coding agent CLI; installs the `grok` command
      "cursor-cli"   # Cursor Agent CLI; installs the `cursor-agent` command
      # Signed wrapper that runs Pi as `pi-signed` (firstmate's pi-signed
      # harness). Apple Silicon only: drop it on an Intel Mac.
      "kunchenguid/tap/pi-launcher"
      # Experimental firstmate runtime backends. Both are GUI apps and need a
      # one-time in-app step, described in README.md.
      "cmux"
      "stablyai/orca/orca"
      "visual-studio-code"
      "google-chrome"
      "opensuperwhisper"            # local Whisper voice dictation for prompting agents
      "kunchenguid/tap/baby-menu"   # menu bar app; shows subscription quota at a glance
      "tailscale-app"               # private network between machines, servers and CI
      # Keychain-backed secrets with per-command approval for agents; the app
      # updates itself. Apple Silicon and macOS Sonoma or newer only.
      "automic-vault/isotopes/automic-vault"
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
