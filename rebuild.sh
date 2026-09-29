#!/usr/bin/env bash
# Builds this flake's system as you, then activates it as root.
# bootstrap.sh runs this for the first switch too, so it must not depend on
# darwin-rebuild, which doesn't exist until the first activation.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# The repo is cloned as you, so evaluate and build as you: Nix writes to
# flake.lock and .git while it evaluates, and doing that under sudo leaves
# root-owned files that break later commits. Only activation needs root, and
# the two sudo lines below are exactly what `darwin-rebuild switch` does after
# it builds. "mac" is the flake host label - keep it in sync with flake.nix.
nix build "$DIR#darwinConfigurations.mac.system" --out-link "$DIR/result"
system="$(readlink -f "$DIR/result")"
# sudo resets PATH to a default without /nix/.../bin, so resolve nix-env first.
# -H gives root its own HOME, as darwin-rebuild does.
NIX_ENV="$(command -v nix-env)"
sudo -H "$NIX_ENV" -p /nix/var/nix/profiles/system --set "$system"
exec sudo -H "$system/activate"
