# dotfiles

My Arch Linux desktop: **[Niri](https://github.com/YaLTeR/niri)** compositor +
the **[iNiR](https://github.com/snowarch/inir)** shell, plus a handful of my own
tweaks (custom keybinds, a `niri-monocle` auto-maximize daemon, fish config,
volume OSD that goes to 150%, and a Vesktop theme).

> 99% of the desktop *is* iNiR. This repo bundles the upstream shell at the
> version I run, pinned, plus my overlay on top.

## Install (fresh Arch machine)

```bash
git clone https://github.com/macaquedev/dotfiles.git
cd dotfiles
./install.sh
```

This will:
1. Install **iNiR** upstream (`./setup install -y`) — pulls Niri, quickshell,
   fonts, the python venv, and the `inir` CLI.
2. Overlay my config into `~/.config`, scripts into `~/.local/bin`, and the
   wallpaper into `~/Shared/Pictures/Wallpapers/`.
3. Resolve the `__HOME__` placeholder to your real home and enable services.

Your existing config is backed up to `~/.config/dotfiles-backup-<timestamp>/`
first. Then log out and pick the **Niri** session in SDDM.

Flags: `--no-inir` (overlay only, iNiR already installed), `--no-backup`.

## Updating (me)

Edit configs in place as normal (`~/.config/niri/…`, etc.), then:

```bash
~/dotfiles/sync                 # pull live config -> repo, commit, push
~/dotfiles/sync "feat: new bind for X"   # custom commit message
~/dotfiles/sync --no-push       # commit locally only
```

`sync` re-reads the manifest in `lib.sh`, copies the live files in, re-templates
your home path, and commits. The pre-commit hook scans for secrets first.

## What's tracked

See `lib.sh` → `ENTRIES`. To add a file to the repo, add one line there; both
`sync` and `install.sh` pick it up automatically.

## Secrets

- Real API keys + AI chat history live in `~/.local/state/quickshell/`, which is
  **never** tracked (`.gitignore` blocks it; the manifest doesn't reference it).
- A `pre-commit` hook (`.githooks/pre-commit`) scans every commit for key
  patterns (Google/OpenAI/Anthropic/GitHub/AWS/Slack/JWT/private keys) and
  aborts on a hit. Enable it after cloning with:
  ```bash
  git config core.hooksPath .githooks
  ```
- Home paths are stored as `__HOME__`, so no username is baked in.
