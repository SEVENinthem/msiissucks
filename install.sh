#!/usr/bin/env bash
# install.sh — ставит msiissucks в ~/.local/bin и, по желанию, автозапуск и плагин Noctalia.
#
#   ./install.sh                       только скрипт (с TUI)
#   ./install.sh --service             + systemd-юнит автозапуска (спросит sudo)
#   ./install.sh --noctalia            + плагин для Noctalia Shell
#   ./install.sh --service --noctalia  всё сразу
#   ./install.sh --uninstall

set -eu
cd "$(dirname "$0")"

BIN="$HOME/.local/bin/msiissucks"
UNIT=/etc/systemd/system/msiissucks.service
PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/msiissucks/noctalia"
PLUGIN_ID="seveninthem/msiissucks"
SOURCE_NAME="msiissucks"

want_service=0
want_noctalia=0

uninstall() {
  if [ -f "$UNIT" ]; then
    sudo systemctl disable --now msiissucks.service || true
    sudo rm -f "$UNIT"
    sudo systemctl daemon-reload
  fi
  if command -v noctalia >/dev/null; then
    noctalia msg plugins disable "$PLUGIN_ID" 2>/dev/null || true
    noctalia msg plugins source remove "$SOURCE_NAME" 2>/dev/null || true
  fi
  rm -rf "$(dirname "$PLUGIN_DIR")"
  rm -f "$BIN"
  rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/msiissucks"
  echo "Удалено."
}

for arg in "$@"; do
  case "$arg" in
    --service)   want_service=1 ;;
    --noctalia)  want_noctalia=1 ;;
    --uninstall) uninstall; exit 0 ;;
    -h|--help)   sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "неизвестный флаг: $arg" >&2; exit 1 ;;
  esac
done

command -v openrgb >/dev/null || echo "⚠ openrgb не найден — установи его (Arch: sudo pacman -S openrgb)" >&2

install -Dm755 msiissucks "$BIN"
echo "Скрипт: $BIN"

if [ $want_service -eq 1 ]; then
  tmp=$(mktemp)
  sed -e "s|@USER@|$(id -un)|g" -e "s|@HOME@|$HOME|g" -e "s|@BIN@|$BIN|g" \
    msiissucks.service.in > "$tmp"
  sudo install -m644 "$tmp" "$UNIT"
  rm -f "$tmp"
  sudo systemctl daemon-reload
  sudo systemctl enable --now msiissucks.service
  echo "Юнит: $UNIT (enabled)"
fi

if [ $want_noctalia -eq 1 ]; then
  command -v noctalia >/dev/null || { echo "noctalia не найден — плагин не установлен" >&2; exit 1; }
  rm -rf "$PLUGIN_DIR"
  mkdir -p "$PLUGIN_DIR"
  cp -r noctalia/msiissucks "$PLUGIN_DIR/"
  if ! noctalia msg plugins source list 2>/dev/null | grep -q "^$SOURCE_NAME "; then
    noctalia msg plugins source add "$SOURCE_NAME" path "$PLUGIN_DIR"
  else
    noctalia msg plugins update "$SOURCE_NAME" || true
  fi
  noctalia msg plugins enable "$PLUGIN_ID"
  echo "Плагин Noctalia: $PLUGIN_ID (из $PLUGIN_DIR)"
  echo "Добавь виджет на панель: Настройки → Панель → Добавить виджет → msiissucks,"
  echo "и плитку: Настройки → Центр управления → Ярлыки."
fi
