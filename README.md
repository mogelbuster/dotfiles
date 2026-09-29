# dotfiles

<p align="center">
  <a href="https://discord.gg/Wsy2NpnZDu"
    ><img
      alt="Discord"
      src="https://img.shields.io/discord/1439901831038763092?style=flat-square&label=discord"
  /></a>
</p>

Watch the walkthrough: https://youtu.be/5N-okeDdIuI

My personal Mac setup, managed with nix-darwin and home-manager.
One repo, one command, and a fresh Mac ends up configured the same way every time.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## What you get

Running the switch builds:

- System settings (dark mode, key repeat, dock, Finder, trackpad)
- Homebrew apps (casks and CLI tools)
- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Neovim, gh, tmux, zellij, treehouse, Hack Nerd Font)
- Shell (zsh, aliases, starship prompt)
- Editor (Neovim config with the rose-pine moon theme)
- VS Code (cask, a short extension list, and a symlinked settings.json with the same theme and font)
- Google Chrome
- Terminal (WezTerm config with the rose-pine moon theme and dimmed unfocused windows)
- Coding agents: Claude Code, Codex, opencode, Grok Build, Cursor Agent CLI, Pi, Pi Launcher (`pi-signed`) and Oh My Pi (`omp`); Claude Code, Codex and opencode share one AGENTS.md
- The rest of the [firstmate](https://github.com/kunchenguid/firstmate) toolchain: GitHub CLI, tmux, zellij, cmux, Orca, treehouse, no-mistakes and the axi CLIs (see "Firstmate toolchain" below)
- Pi theme and local extensions, generic UI settings and model overrides, plus two deliberately pinned third-party Pi packages

## Prerequisites

- Apple Silicon Mac, by default.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).
- Apple's Command Line Tools, from `xcode-select --install`.
  They provide git, which you need to clone this repo, and Homebrew needs them too.
  This config uses that git rather than declaring its own: Apple's build carries a built-in config that stores credentials in the macOS Keychain and names new branches `main`, which a separately installed git would silently drop.

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/kunchenguid/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Change the host label or CPU architecture if needed, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username, and offers to fix it for you if they differ.
4. Runs `rebuild.sh` for the first switch, applying this repo's locked flake config.

After that, you're on the normal workflow below.

`rebuild.sh` builds as you and uses `sudo` only to activate.
Nix writes to `flake.lock` and `.git` while it evaluates (it locks any new input on first use), so building under `sudo` would leave root-owned files there that break your next commit.
If an older run already did, fix it once with `sudo chown -R "$USER" flake.lock .git`.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), you can check that the config builds without touching your system - handy when you have edited something:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

If you renamed the host label in "Make it yours", substitute your label for `mac` in these commands.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your macOS username and offers to set it) OR change the single `user = "kunchen"` line in `flake.nix`.
  Everything else (`configuration.nix`, `home.nix`, home directory paths) is threaded from that one variable.
- **Host label** `"mac"`, in two places: `flake.nix` (the `darwinConfigurations."mac"` name) and `rebuild.sh` (the `darwinConfigurations.mac` in its flake reference).
  Both have to match.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).

**Git identity:** this config deliberately does not set your git name or email.
Git will stop your first commit and tell you to set them (`git config --global user.name "Your Name"` and `git config --global user.email you@example.com`).
If you'd rather manage that declaratively, add this back to `home.nix` with your own identity:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew cleanup warning:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**About `herdr`:** it's in the `brews` list.
It's a real public Homebrew formula (`brew info herdr` finds it in homebrew-core, no tap needed), so it will install fine.
If you don't use it, just remove it from `brews` in your copy.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `home.nix` installs it for Claude, Codex, and opencode.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.
- The `cc` and `co` shell aliases in `home.nix` are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.
  They're convenient for me, but know what they do before you use them.
- Two Home Manager activation steps reach the network on a rebuild when something is missing: one runs `npm install -g` for the packages listed in `npmGlobals` in `home.nix`, the other runs the official no-mistakes installer.
  Both are skipped once the tool is present. Trim `npmGlobals` or drop `home.activation.noMistakes` if you don't use firstmate.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config: shell, packages, prompt, and the symlinks described below.
- `rebuild.sh` - applies the config; `bootstrap.sh` uses it for the first switch.
  Run this every time you make a change.
- `home/` - the actual config files that get symlinked into place; the sections below explain the shared symlink model and Pi's narrower selective setup.

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

## Firstmate toolchain

I run [firstmate](https://github.com/kunchenguid/firstmate) as my primary agent, so this config declares every harness its README recommends and every tool its session-start toolchain check looks for.
Firstmate itself is not installed by this repo: it is a cloned directory you launch a harness inside, per its README.

| What firstmate wants | Declared where |
| --- | --- |
| Claude Code, Codex, Grok Build (`grok`), Cursor Agent CLI (`cursor-agent`), Pi Launcher (`pi-signed`), cmux, Orca | `casks` in `configuration.nix` |
| opencode, Oh My Pi (`omp`), node | `brews` in `configuration.nix` |
| git | Apple's Command Line Tools (see Prerequisites) |
| gh, tmux, zellij, treehouse | `home.packages` in `home.nix` (treehouse comes from its flake, wired in `flake.nix`) |
| Pi, tasks-axi, quota-axi, gh-axi, chrome-devtools-axi, lavish-axi | `npmGlobals` in `home.nix`, installed by `home.activation.npmGlobals` |
| no-mistakes | `home.activation.noMistakes` in `home.nix`, using the official installer |

One-time steps this config cannot do for you, because each edits agent state or needs a GUI:

- `gh auth login`.
- `gh-axi setup hooks`, `chrome-devtools-axi setup hooks` and `lavish-axi setup hooks` add session hooks to Claude Code, Codex and opencode. `~/.claude/settings.json` is a symlink into this repo, so review and commit the resulting change to `home/.claude/settings.json`.
- Launch Grok with `grok --trust` and Cursor with `cursor-agent --trust` once per firstmate clone so its project hooks load; approve Pi's project trust prompt once.
- cmux: open Settings > Automation and choose a Socket Control Mode before the first cmux-backed spawn.
- Orca: open the app once so it is running and ready; the cask already links the `orca` CLI into `/opt/homebrew/bin`.
- Herdr, cmux, zellij and Orca are alternatives to the tmux default; firstmate picks tmux unless you select another backend.

Deliberately not declared: firstmate's optional voice relay (needs a second machine and a Python venv), the Firstmate 3000 desktop app (private alpha), and the harnesses firstmate verifies only for crewmates rather than as a primary (Gemini CLI, Kimi, Muse, Rovo, agy, Devin).
Add `gemini-cli` or `kimi-code` to `brews` if you want those workers.

## Pi configuration

Pi is installed as a global npm package through `npmGlobals` in `home.nix`, and [Pi Launcher](https://github.com/kunchenguid/homebrew-tap) as the `kunchenguid/tap/pi-launcher` cask in `configuration.nix`, which provides the `pi-signed` command firstmate uses for its signed-wrapper harness identity.
The launcher is Apple Silicon only; drop it from `casks` on an Intel Mac.

Home Manager owns exactly two repository-authored Pi directories: `~/.pi/agent/themes` and `~/.pi/agent/extensions`. It also links `models.json` and `settings.json` as individual files. The local extension directory is for public, repository-authored extensions only - third-party package code never belongs there. Run `/reload` after editing a local extension or other Pi resources. The terminal-title extension shows a spinner while Pi is working, then a completion mark with the session name or current directory. The `rose-pine-moon` theme was authored clean-room from the public [Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's [public theme schema](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json), not from a private or live theme file.

### Pi Calm

`home/.pi/agent/extensions/calm` is a standalone local Pi extension. Home Manager's existing global extensions-directory link makes Pi auto-load it without another declaration. `/calm` toggles a conversation-only presentation mode and is off by default. Its choice is stored locally in `~/.pi/agent/calm` (or the directory selected by `PI_CODING_AGENT_DIR`), not in this repository or Home Manager. Adapted from Firstmate under the bundled MIT license, Calm imports no Firstmate modules and has no Firstmate runtime dependency.

When enabled, Calm hides collapsed thinking and the call/result shells for Pi's seven built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`) without leaving blank transcript rows. During an active run it replaces Pi's working row with a two-line animated blue-water, yellow-boat widget. `/calm` restores Pi's stock rendering and preserves the existing Ctrl+O tool-expansion choice.

Calm never changes prompts, tool execution, model context, session data, or ordering. `/share` and `/export` use the complete stock transcript. Generic custom tools, images, and unsupported Pi transcript classes deliberately remain visible because Pi has no safe general-purpose transcript filter. If a future Pi release no longer exports the exact collapsed-thinking rendering seam, Calm logs one diagnostic and leaves only that adapter disabled; all other behavior remains available.

Pi's package system declares two third-party sources in the linked global `settings.json`:

- `npm:pi-web-access@0.14.0` - the exact public npm release for web access.
- `npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.6` - the exact public npm release from `ryan_nookpi`.

The versions are immutable pins, so Pi does not move them during package updates. Deliberate updates require a new source and security audit, followed by an explicit pin change in `home/.pi/agent/settings.json`. On Pi 0.82.0, global settings declarations install missing pinned packages automatically at startup. No one-time install command is required. Pi keeps the downloaded npm package trees in its own unmanaged `~/.pi/agent/npm` runtime directory, outside Home Manager and Git tracking.

Both packages execute with your full user permissions and must be trusted like any other executable code.

Home Manager deliberately does not manage `~/.pi/agent` itself, or Pi authentication, sessions, trust decisions, caches, npm/git package trees, or any other runtime state. The model overrides contain no credentials or endpoint settings, do not choose a default model, and only take effect after you authenticate Pi yourself. No Pi or package source code is vendored into this repository.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
