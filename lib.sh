#!/usr/bin/env bash
# Shared manifest + helpers for sync (live -> repo) and install (repo -> live).
# Single source of truth: edit ENTRIES here and both directions stay in sync.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Each entry: "LIVE_REL|REPO_REL|TYPE"
#   LIVE_REL  path relative to $HOME on a real system
#   REPO_REL  path relative to repo root
#   TYPE      file | dir | qs | bin | wall
ENTRIES=(
  ".config/niri/config.kdl|config/niri/config.kdl|file"
  ".config/niri/config.d|config/niri/config.d|dir"
  ".config/inir/config.json|config/inir/config.json|file"
  ".config/fish/config.fish|config/fish/config.fish|file"
  ".config/fish/conf.d/fish_frozen_key_bindings.fish|config/fish/conf.d/fish_frozen_key_bindings.fish|file"
  ".config/fish/conf.d/fish_frozen_theme.fish|config/fish/conf.d/fish_frozen_theme.fish|file"
  ".config/fish/functions/teamviewer.fish|config/fish/functions/teamviewer.fish|file"
  ".config/systemd/user/niri-monocle.service|config/systemd/user/niri-monocle.service|file"
  ".config/vesktop/themes/inir-midnight.theme.css|config/vesktop/inir-midnight.theme.css|file"
  ".config/quickshell/inir|config/quickshell/inir|qs"
  ".local/bin/niri-monocle|bin/niri-monocle|bin"
  ".local/bin/niri-stack-nav|bin/niri-stack-nav|bin"
  ".local/bin/gemini-screenshot|bin/gemini-screenshot|bin"
  ".local/bin/vivaldi-open|bin/vivaldi-open|bin"
  "Shared/Pictures/Wallpapers/wp.jpg|wallpapers/wp.jpg|wall"
)

# Files matching these globs are never copied in either direction.
QS_EXCLUDES=(--exclude='__pycache__' --exclude='*.pyc' --exclude='.git' --exclude='.venv')

HOME_TOKEN='__HOME__'

# Portable recursive copy honoring quickshell excludes.
_copy_tree() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${QS_EXCLUDES[@]}" "$src/" "$dst/"
  else
    rm -rf "$dst"; mkdir -p "$dst"
    cp -a "$src/." "$dst/"
    find "$dst" \( -name '__pycache__' -o -name '*.pyc' -o -name '.venv' \) -exec rm -rf {} + 2>/dev/null || true
  fi
}

# Replace every occurrence of $1 with $2 across text files under $3 (skips binaries).
_template_dir() {
  local from="$1" to="$2" root="$3" f
  while IFS= read -r f; do
    sed -i "s#${from}#${to}#g" "$f"
  done < <(grep -rlIF "$from" "$root" 2>/dev/null || true)
}
