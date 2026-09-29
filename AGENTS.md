# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional. It forces the good habit of declaring every Homebrew package in the Nix config instead of installing things ad-hoc, which keeps the machine reproducible. Do not soften it to `uninstall` or `none`. Users are warned about its effect in README.md; this note is for anyone tempted to change the setting itself.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.
- The agent harnesses and tools across `configuration.nix`, `home.nix` and `flake.nix` mirror what [firstmate](https://github.com/kunchenguid/firstmate) recommends and checks for at session start (its README "Requirements" plus `COMMON_TOOLS` and the per-backend list in its `bin/fm-bootstrap.sh`). README.md "Firstmate toolchain" maps each tool to where it is declared; keep that table and the config in step when adding or removing agent tooling.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
