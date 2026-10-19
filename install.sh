#!/usr/bin/env bash
# install.sh — ставит msiissucks в ~/.local/bin и (по желанию) юнит автозапуска.
#
#   ./install.sh            только скрипт
#   ./install.sh --service  скрипт + systemd-юнит (спросит sudo)
#   ./install.sh --uninstall

set -eu
cd "$(dirname "$0")"

BIN="$HOME/.local/bin/msiissucks"
UNIT=/etc/systemd/system/msiissucks.service

case "${1:-}" in
  --uninstall)
    if [ -f "$UNIT" ]; then
      sudo systemctl disable --now msiissucks.service || true
      sudo rm -f "$UNIT"
      sudo systemctl daemon-reload
    fi
    rm -f "$BIN"
    rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/msiissucks"
    echo "Удалено."
    exit 0
    ;;
esac

command -v openrgb >/dev/null || echo "⚠ openrgb не найден — установи его (Arch: sudo pacman -S openrgb)" >&2

install -Dm755 msiissucks "$BIN"
echo "Скрипт: $BIN"

if [ "${1:-}" = "--service" ]; then
  tmp=$(mktemp)
  sed -e "s|@USER@|$(id -un)|g" -e "s|@HOME@|$HOME|g" -e "s|@BIN@|$BIN|g" \
    msiissucks.service.in > "$tmp"
  sudo install -m644 "$tmp" "$UNIT"
  rm -f "$tmp"
  sudo systemctl daemon-reload
  sudo systemctl enable --now msiissucks.service
  echo "Юнит: $UNIT (enabled)"
fi
