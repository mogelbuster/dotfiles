# Manual setup

Everything this repo cannot do for you, in the order to do it.
`bootstrap.sh` (or `rebuild.sh`) installs the software; this guide covers the sign-ins, permissions, app settings and accounts that have to be done by a person, so the machine ends up with the full agentic workflow: firstmate running a crew of agents in herdr, voice prompts, visual planning in lavish, and no-mistakes validating changes.

Work top to bottom on a fresh machine.
On an existing machine, pick up any section you have not done yet.
Each section says when it is optional.

## Running in a virtual machine

Skip this if the dotfiles are on a physical Mac.

- **Size the VM before setting up.** The workflow runs a first mate, several crew agents, Chrome and VS Code at once, and every crew task gets its own git worktree.
  Give it about 24 GB of RAM (16 GB minimum), 8 or more CPU cores, and about 200 GB of disk (250 GB or more if you will install Xcode).
  Growing a VM's disk and RAM after the fact is far more work than sizing it up front.
- **Voice input runs on the host, not in the VM.** The VM does not receive the host's microphone, so OpenSuperWhisper installed inside it hears nothing.
  Install OpenSuperWhisper on the host Mac instead: it types the transcription into whichever window has focus, so dictating into the VM's window works as if you typed it.
  The copy this repo installs inside the VM can stay unused.

## 1. Open a new terminal

After the first switch, quit your terminal and open WezTerm.
New PATH entries (`~/.local/bin`, Homebrew, the Nix profile) and environment variables only apply to terminals started after the switch.

Check the core tools resolve:

```sh
for t in node gh git no-mistakes treehouse herdr claude codex pi kimi gh-axi quota-axi lavish-axi; do
  printf "%-14s %s\n" "$t" "$(command -v "$t" || echo MISSING)"
done
```

`git` should be `/usr/bin/git` (Apple's, from the Command Line Tools).
Anything `MISSING` means the switch did not finish: read its output and re-run `./rebuild.sh`.

## 2. GitHub and git

```sh
gh auth login
```

Pick GitHub.com, HTTPS, answer **Yes** to "Authenticate Git with your GitHub credentials", and log in with the browser.

`gh auth login` writes git's credential helper as the exact Nix store path of the current `gh`, which breaks the next time a rebuild updates `gh`.
Point it at the stable profile path instead:

```sh
git config --global --replace-all credential.https://github.com.helper '!/etc/profiles/per-user/'"$USER"'/bin/gh auth git-credential' 'gh'
git config --global --replace-all credential.https://gist.github.com.helper '!/etc/profiles/per-user/'"$USER"'/bin/gh auth git-credential' 'gh'
```

Do not run `gh auth setup-git` afterwards; it writes the fragile path back.

Set your identity (type straight quotes; curly quotes pasted from a web page end up inside the value):

```sh
git config --global user.name "Your Name"
git config --global user.email "12345+you@users.noreply.github.com"
```

Your noreply address is under github.com > Settings > Emails.
Check the result with `cat ~/.gitconfig`: no quote marks in the values, and both `helper = !...` lines start with `/etc/profiles/per-user/`.

## 3. Sign in to the agent harnesses

Run each once and follow its login flow:

| Harness | Command | Notes |
| --- | --- | --- |
| Claude Code | `claude` | Anthropic subscription. |
| Codex | `codex` | ChatGPT subscription. |
| Pi | `pi`, then `/login` | Log in to each provider you use (OpenAI, Anthropic, xAI, Kimi and others). |
| Grok | `grok` | xAI subscription. |
| Cursor Agent | `cursor-agent` | Cursor subscription. |
| Kimi Code | `kimi` | Creates `~/.kimi-code/config.toml`; firstmate refuses Kimi crewmates until that file exists. |
| opencode, Oh My Pi | `opencode`, `omp` | Only if you use them. |

You only need the subscriptions you intend to route work to.
The full set in the reference workflow is Claude (Opus, Fable, Sonnet), ChatGPT for Codex (GPT 5.6 Sol and Luna, Astra), Kimi, Grok and Cursor.

## 4. Agent session hooks

```sh
gh-axi setup hooks
chrome-devtools-axi setup hooks
lavish-axi setup hooks
```

These add SessionStart hooks to Claude Code, Codex and opencode so every session starts knowing about each tool.
`~/.claude/settings.json` is a symlink into this repo, so the Claude change lands in `home/.claude/settings.json`: review it with `git diff` and commit it.
The Codex and opencode hook files live outside the repo, so on a new machine you simply re-run these three commands.

## 5. Browser control for agents

This config sets `CHROME_DEVTOOLS_AXI_AUTO_CONNECT=1`, so `chrome-devtools-axi` drives your real, signed-in Chrome instead of launching a blank one.
That only works once Chrome allows it:

1. Open `chrome://inspect/#remote-debugging` in Chrome.
2. Turn on remote debugging for this browser instance and leave it on.

Chrome asks for permission each time a new agent session attaches.
Anything signed in to that Chrome is reachable by the agent, so only approve sessions you started.

## 6. Apps

Open each once and finish its first-run setup.

- **OpenSuperWhisper** (voice prompts; in a VM, do this on the host instead, see "Running in a virtual machine"): grant microphone and accessibility access and pick the keyboard shortcut that starts recording.
  For the model, choose the **Whisper** engine, not Parakeet: only Whisper supports the initial prompt below.
  All three Whisper options are the same large-v3-turbo model at different compression levels; **Whisper V3 Large** is the full-quality one (older app versions call it "Turbo V3 large").
  Pick Medium or Small only if the machine is short on memory.
  Under the transcription settings, add your project names and jargon to the **initial prompt** so they transcribe correctly.
- **Automic Vault** (secrets for agents): see section 7.
- **Tailscale**: sign in. Add every machine and server you want agents to reach.
- **baby-menu** (quota in the menu bar): open it once. It builds its menu with an already signed-in agent CLI such as `claude`, so do section 3 first.
- **Herdr**: run `herdr` once and finish onboarding. The keybindings mirror tmux with `ctrl+b` as the prefix (`home/.config/herdr/config.toml`).
- **Orca** (optional firstmate backend): open the app once so it is running.
- **cmux** (optional firstmate backend): Settings > Automation > Socket Control Mode > **Automation mode**.

## 7. Secrets with Automic Vault

Keep API tokens out of `.env` files and shell history.
Agents use a secret through Automic Vault, you approve each use, and the agent never sees the value.

Open the app, then install its command-line tool:

```sh
open "/Applications/Automic Vault.app"
```

1. Opening the app shows its window and puts an Automic Vault icon in the menu bar.
   You can close the window; the menu bar icon keeps running in the background.
2. Click that menu bar icon and choose **Install av CLI**.
   It asks for your password because it installs to `/usr/local/bin/av`.
3. In a new terminal, `av --version` should print a version.

```sh
av scan            # finds credentials stored in exposed places
```

Store a token (it prompts, so the value never reaches your shell history):

```sh
av save HCLOUD_TOKEN
av save CLOUDFLARE_API_TOKEN
```

Then tell your agents the secret's name, not its value.

Recommended access levels from the Automic Vault README: default gates to approval required, agents to read only, your terminal to write.
Turn on Touch ID approval in its settings.

Hardening a tool (`av harden gh`, then `av doctor gh`) moves that tool's credential into the Keychain and can install an Automic Vault build of it or a wrapper.
That changes a tool this repo also manages, so run `av doctor <tool>` after each rebuild to confirm the protection is intact, and do not harden `gh` without re-checking section 2 afterwards.

## 8. Firstmate

Firstmate is not installed by this repo; it is a directory you clone and run an agent inside.

```sh
mkdir -p ~/source && cd ~/source
git clone https://github.com/kunchenguid/firstmate
```

Launch it inside herdr so herdr becomes its backend automatically:

```sh
herdr
cd ~/source/firstmate
claude            # or: pi, grok --trust, cursor-agent --trust
```

- Answer yes to the folder trust prompt so firstmate's hooks load.
  Grok and Cursor need `--trust` once per clone; Pi asks once.
- On its first turn firstmate checks its toolchain.
  If it offers to install or upgrade something, decline and add it to this repo instead (`zap` would remove anything installed by hand).
- Add a project by talking to it, for example: `ahoy! add my github project you/repo in direct-PR mode, then fix <something small>`.

Configure the fleet by describing what you want to the first mate; it writes these gitignored files for you:

| What | Where | Example request |
| --- | --- | --- |
| Per-project merge policy | `data/projects.md` | "use no-mistakes for repo X", "direct-PR plus yolo for my toy projects" |
| Which harness and model handles which kind of task | `config/crew-dispatch.json` | "use Fable for UI work, Luna for simple bug fixes, pick whichever has the most quota" |
| Discord and X mentions (optional) | `.env`, `FMX_PAIRING_TOKEN` | see "Relay (.env)" in firstmate's `docs/configuration.md` |

Useful commands inside firstmate: `/bearings` for fleet status, `/ahoy` to catch up, `/afk` before stepping away.
On Pi, `/calm` hides tool-call noise.

## 9. Skills (optional)

Install skills only from sources you trust; a skill can instruct your agent to run anything.
To teach non-Claude agents how to write skills, add Anthropic's Skill Creator with Vercel's skills CLI:

```sh
npx skills add https://github.com/anthropics/skills/tree/main/skills/skill-creator
```

## 10. Accounts for shipping apps (optional)

Only needed for the kinds of projects you build:

- **Claude Design** at claude.ai for design systems, mockups and app icons.
- **A VPS host** such as Hetzner, and **Cloudflare** for DNS. Store their API tokens in Automic Vault (section 7) and let agents provision with OpenTofu.
- **Apple Developer membership** and **Xcode** (App Store) for iOS or Flutter iOS work.

## 11. A second Mac for secondmates (optional)

To scale past one machine, run persistent secondmates on a second Mac, such as a Mac mini with no monitor attached:

1. Apply this repo to it the same way (`bootstrap.sh`), then do sections 1 to 4 there.
2. Keep a GUI login session running on it with herdr started; herdr's remote server belongs to that session.
3. Join both Macs to Tailscale and make sure the primary can SSH to it.
4. Ask your first mate to set up a remote secondmate; firstmate's `docs/remote-secondmates.md` has the details.

## Keeping things current

| What | How |
| --- | --- |
| Homebrew apps and CLIs | `brew upgrade <name>`, or `brew upgrade` for all. Claude Code is `claude-code@latest`. |
| Nix packages (gh, tmux, zellij, treehouse, OpenTofu, ...) | `nix flake update`, then `./rebuild.sh`, then commit `flake.lock`. |
| npm CLIs (Pi, the axi tools, gnhf, backpass) | `npm install -g <name>@latest`. Firstmate tells you when an axi tool falls below the version it needs. |
| no-mistakes | Re-run its installer when firstmate reports it too old: `curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh \| sh` |
| Firstmate | `/updatefirstmate` inside firstmate. |

A running agent keeps the old version until you restart it.
