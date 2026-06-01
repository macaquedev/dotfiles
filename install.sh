#!/usr/bin/env bash
# install.sh — set up this desktop on a fresh Arch machine.
# Installs iNiR (deps + shell) upstream, then overlays this config.
#
#   git clone https://github.com/macaquedev/dotfiles.git
#   cd dotfiles && ./install.sh
#
# Flags:  --no-inir   skip the upstream iNiR install (config overlay only)
#         --no-backup do not back up existing config before overwriting
#         --keyd      install the keyd config without asking
#         --no-keyd   skip the keyd config without asking
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DO_INIR=1; DO_BACKUP=1; KEYD=ask
for arg in "$@"; do
  case "$arg" in
    --no-inir)   DO_INIR=0 ;;
    --no-backup) DO_BACKUP=0 ;;
    --keyd)      KEYD=yes ;;
    --no-keyd)   KEYD=no ;;
  esac
done

if [[ "$(uname -s)" != "Linux" ]] || ! command -v pacman >/dev/null 2>&1; then
  echo "!! This config targets Arch Linux + Niri. Aborting." >&2
  exit 1
fi

BACKUP="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# 1. iNiR base (compositor deps, quickshell runtime, fonts, venv, the `inir` CLI)
if [[ "$DO_INIR" -eq 1 ]]; then
  echo "==> Installing iNiR upstream (deps + shell)"
  tmp="$(mktemp -d)"
  git clone --depth 1 https://github.com/snowarch/inir.git "$tmp/inir"
  ( cd "$tmp/inir" && ./setup install -y )
  rm -rf "$tmp"
else
  echo "==> Skipping iNiR install (--no-inir); assuming it is already present"
fi

# 2. Overlay this repo's config on top
echo "==> Overlaying config into \$HOME"
for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r live repo type <<<"$entry"
  src="$REPO_ROOT/$repo" dst="$HOME/$live"
  [[ -e "$src" ]] || { echo "   skip (not in repo): $repo"; continue; }

  if [[ "$DO_BACKUP" -eq 1 && -e "$dst" ]]; then
    mkdir -p "$BACKUP/$(dirname "$live")"
    cp -a "$dst" "$BACKUP/$live"
  fi

  case "$type" in
    dir|qs) _copy_tree "$src" "$dst" ;;
    bin)    mkdir -p "$(dirname "$dst")"; cp -a "$src" "$dst"; chmod +x "$dst" ;;
    *)      mkdir -p "$(dirname "$dst")"; cp -a "$src" "$dst" ;;
  esac
  echo "   $live"
done

# 3. Resolve the home placeholder to this user's real home
echo "==> Resolving $HOME_TOKEN -> $HOME"
for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r live _ type <<<"$entry"
  [[ "$type" == "wall" ]] && continue
  _template_dir "$HOME_TOKEN" "$HOME" "$HOME/$live"
done

[[ "$DO_BACKUP" -eq 1 && -d "$BACKUP" ]] && echo "==> Previous config backed up to: $BACKUP"

# 3.5 ydotool — the bar uses it to warp the cursor back after a workspace click
#     (niri's warp-mouse-to-focus would otherwise fling the pointer to center).
echo "==> Setting up ydotool (cursor warp-back on workspace clicks)"
command -v ydotoold >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm ydotool \
  || echo "   !! install the 'ydotool' package manually"
# Let ydotoold run as your user (needs /dev/uinput access).
if [[ ! -f /etc/udev/rules.d/80-uinput.rules ]]; then
  echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' \
    | sudo tee /etc/udev/rules.d/80-uinput.rules >/dev/null
  sudo udevadm control --reload-rules && sudo udevadm trigger
fi
id -nG | grep -qw input || { sudo usermod -aG input "$USER"; NEED_RELOGIN=1; }
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/ydotoold.service" <<'UNIT'
[Unit]
Description=ydotool daemon
[Service]
ExecStart=/usr/bin/ydotoold
Restart=on-failure
[Install]
WantedBy=default.target
UNIT

# 4. Enable user services + reload niri
echo "==> Enabling services"
systemctl --user daemon-reload || true
systemctl --user enable --now ydotoold.service 2>/dev/null \
  || echo "   (ydotoold will start after a re-login if uinput access was just granted)"
systemctl --user enable --now niri-monocle.service 2>/dev/null \
  || echo "   (niri-monocle will start under niri.service — enabled via WantedBy)"
command -v niri >/dev/null && niri msg action load-config-file 2>/dev/null || true

# 5. keyd — OPTIONAL system-wide key remapping (the person chooses).
echo "==> keyd key remapping (optional)"
cat <<'KEYD_INFO'
   keyd remaps keys in the kernel, so it works everywhere (Wayland, X, TTYs).
   This config does:
     • Tap Left Super alone   -> F13  (niri binds it to the app launcher)
     • Hold Left Super        -> normal Super modifier (all Mod+… binds still work)
     • Caps Lock: tap -> Esc, hold -> Ctrl;   Esc key -> Caps Lock
     • Hold Caps Lock as a layer:
         h/j/k/l = ← ↓ ↑ →       q/w/e/r = Ctrl+A/X/C/V
         s/d = Ctrl+Z / Ctrl+Y   Backspace = Ctrl+Backspace
KEYD_INFO

install_keyd=0
case "$KEYD" in
  yes) install_keyd=1 ;;
  no)  echo "   Skipping keyd (--no-keyd)." ;;
  ask)
    if [[ -t 0 ]]; then
      read -rp "   Install this keyd config? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && install_keyd=1 || echo "   Skipping keyd."
    else
      echo "   Non-interactive run; skipping keyd (re-run with --keyd to install)."
    fi ;;
esac

if [[ "$install_keyd" -eq 1 ]]; then
  command -v keyd >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm keyd
  sudo mkdir -p /etc/keyd
  # Never overwrite an existing config: back it up in place (and don't clobber
  # a previous .bak either).
  if [[ -e /etc/keyd/default.conf ]]; then
    bak=/etc/keyd/default.conf.bak
    [[ -e "$bak" ]] && bak="/etc/keyd/default.conf.$(date +%Y%m%d-%H%M%S).bak"
    sudo cp -a /etc/keyd/default.conf "$bak"
    echo "   Existing keyd config backed up to $bak"
  fi
  sudo cp "$REPO_ROOT/system/keyd/default.conf" /etc/keyd/default.conf
  sudo systemctl enable --now keyd
  sudo keyd reload 2>/dev/null || sudo systemctl restart keyd || true
  echo "   keyd installed and reloaded."
fi

cat <<EOF

==> Done.
   Log out and back in (pick the Niri session in SDDM), or restart Niri.
   Wallpaper installed at: ~/Shared/Pictures/Wallpapers/wp.jpg
${NEED_RELOGIN:+   NOTE: you were added to the 'input' group — log out/in for the
         workspace-click cursor warp-back to work.}
EOF
