{ config, lib, pkgs, user, treehouse, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # Global npm CLIs firstmate expects on PATH: Pi and its axi toolbelt. They
  # install through Homebrew's node, so `npm install -g` needs no prefix setup
  # and firstmate's own consent-gated installer keeps working. Installed if
  # missing on every rebuild, unpinned: firstmate reports a tool below its
  # version floor at session start, and `npm install -g <name>@latest` moves it.
  npmGlobals = [
    "@earendil-works/pi-coding-agent"  # Pi
    "tasks-axi"                        # backlog transitions
    "quota-axi"                        # provider quota checks
    "gh-axi"                           # GitHub from agents; `gh-axi setup hooks` once
    "chrome-devtools-axi"              # browser automation; `chrome-devtools-axi setup hooks` once
    "lavish-axi"                       # optional visual decisions and reports; `lavish-axi setup hooks` once
    "gnhf"                             # long-running agent loops ("good night, have fun")
    "backpass"                         # proposes AGENTS.md edits from past agent sessions
  ];

  # VS Code extensions (marketplace `publisher.name` IDs, lowercase).
  # Installed if missing on every rebuild. Extensions added from the VS Code UI
  # are left alone; remove one here and uninstall it in VS Code to drop it.
  vscodeExtensions = [
    "anthropic.claude-code"  # Claude Code
    "openai.chatgpt"         # Codex
    "jnoortheen.nix-ide"     # Nix syntax and formatting for this repo
    "mvllow.rose-pine"       # same theme as Neovim and WezTerm
    "dart-code.dart-code"    # Dart
    "dart-code.flutter"      # Flutter; depends on dart-code.dart-code
  ];
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    # firstmate's universal toolchain and session backends. git is not here:
    # Apple's Command Line Tools already provide it (see README Prerequisites).
    gh        # GitHub CLI; run `gh auth login` once
    tmux      # reference runtime backend
    zellij    # experimental runtime backend
    treehouse.packages.${pkgs.stdenv.hostPlatform.system}.default  # worktree pool
    opentofu  # infrastructure as code for servers agents provision
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";
  # Agents drive your real, signed-in Chrome instead of a blank isolated one.
  # Needs Chrome's remote debugging switched on once (MANUAL-SETUP.md).
  home.sessionVariables.CHROME_DEVTOOLS_AXI_AUTO_CONNECT = "1";
  # no-mistakes links its command here (see the activation step below).
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  # VS Code reads user settings from Library/Application Support on macOS; the
  # repo copy lives under .config/vscode to keep the path short.
  home.file."Library/Application Support/Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/vscode/settings.json";
  # Runs after Homebrew, so the VS Code cask is already installed. Skips quietly
  # if it isn't, so a missing editor never blocks the rest of activation.
  home.activation.vscodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    code=/opt/homebrew/bin/code
    if [ -x "$code" ]; then
      installed="$("$code" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
      for ext in ${lib.concatStringsSep " " vscodeExtensions}; do
        if ! printf '%s\n' "$installed" | grep -qx "$ext"; then
          run "$code" --install-extension "$ext" || echo "VS Code extension $ext failed to install" >&2
        fi
      done
    else
      echo "VS Code not found at $code, skipping extensions" >&2
    fi
  '';

  # Runs after Homebrew, so brew's node is already installed. A scoped package
  # lives at <npm root>/@scope/name, so one directory test covers both shapes.
  home.activation.npmGlobals = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    npm=/opt/homebrew/bin/npm
    # npm is a `#!/usr/bin/env node` script and activation's PATH has no
    # Homebrew, so give each npm call brew's bin or it cannot find node.
    brewPath="/opt/homebrew/bin:$PATH"
    if [ -x "$npm" ]; then
      root="$(PATH="$brewPath" "$npm" root -g 2>/dev/null)"
      for pkg in ${lib.concatStringsSep " " npmGlobals}; do
        if [ ! -d "$root/$pkg" ]; then
          run env PATH="$brewPath" "$npm" install -g "$pkg" || echo "npm package $pkg failed to install" >&2
        fi
      done
    else
      echo "npm not found at $npm, skipping global npm packages" >&2
    fi
  '';

  # no-mistakes (firstmate's ship gate) has no Homebrew formula or Nix package,
  # so this runs its official installer when the binary is missing. It lands in
  # ~/.no-mistakes/bin with the command linked from ~/.local/bin, which is on
  # PATH through home.sessionPath, so no sudo is needed. Upgrades are
  # deliberate: rerun the installer when firstmate reports it below its floor.
  home.activation.noMistakes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "$HOME/.no-mistakes/bin/no-mistakes" ]; then
      run mkdir -p "$HOME/.local/bin"
      # Activation's PATH has no macOS system dirs, but the installer calls
      # curl, tar and uname, then starts its daemon with /bin/launchctl.
      run env PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH" \
        NO_MISTAKES_LINK_DIR="$HOME/.local/bin" /bin/sh -c \
        '/usr/bin/curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | /bin/sh' \
        || echo "no-mistakes failed to install" >&2
    fi
  '';

  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
