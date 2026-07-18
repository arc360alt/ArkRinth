#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="$(find "$DIR" -maxdepth 1 -type f -executable ! -name '*.sh' | head -1)"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" \
	"$HOME/.local/share/icons/hicolor/128x128/apps" \
	"$HOME/.local/share/icons/hicolor/256x256@2/apps"

cp "$BIN_PATH" "$HOME/.local/bin/nyxrinth-app"
chmod +x "$HOME/.local/bin/nyxrinth-app"
cp "$DIR/icons/128x128.png" "$HOME/.local/share/icons/hicolor/128x128/apps/nyxrinth-app.png"
cp "$DIR/icons/256x256.png" "$HOME/.local/share/icons/hicolor/256x256@2/apps/nyxrinth-app.png"

sed -e "s|^Exec=.*|Exec=$HOME/.local/bin/nyxrinth-app|" \
	-e "s|^Icon=.*|Icon=nyxrinth-app|" \
	"$DIR/nyxrinth-app.desktop" >"$HOME/.local/share/applications/nyxrinth-app.desktop"

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "Installed to $HOME/.local/bin/nyxrinth-app"
echo "Make sure ~/.local/bin is in your PATH, then run: nyxrinth-app"
echo "(or find \"NyxRinth App\" in your application launcher)"
