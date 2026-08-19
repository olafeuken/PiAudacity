#!/usr/bin/env bash
# Instalacja Audacity 4 (build aarch64) z GitHub Release.
set -euo pipefail

REPO="olafeuken/PiAudacity"
APP_NAME="Audacity"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Pobieranie najnowszego Release ..."
FILE=""
if command -v gh >/dev/null 2>&1 && gh api user >/dev/null 2>&1; then
  FILE="$(gh api "repos/$REPO/releases" --jq '.[0].assets[] | select(.name | endswith(".AppImage")) | .name' | head -1)"
  if [ -n "$FILE" ]; then
    ASSET_ID="$(gh api "repos/$REPO/releases" --jq '.[0].assets[] | select(.name | endswith(".AppImage")) | .id' | head -1)"
    gh api -H "Accept: application/octet-stream" "repos/$REPO/releases/assets/$ASSET_ID" > "$TMP_DIR/$FILE"
  fi
fi

if [ -z "$FILE" ] || [ ! -s "$TMP_DIR/$FILE" ]; then
  ASSET_URL="$(curl -s "https://api.github.com/repos/$REPO/releases" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    if not isinstance(d, list):
        d = []
    print(next((a["browser_download_url"] for r in d for a in r.get("assets", []) if a["name"].endswith(".AppImage")), ""))
except Exception:
    print("")
')"
  if [ -n "$ASSET_URL" ]; then
    FILE="$(basename "$ASSET_URL")"
    curl -L --fail -o "$TMP_DIR/$FILE" "$ASSET_URL"
  fi
fi

if [ -z "$FILE" ] || [ ! -s "$TMP_DIR/$FILE" ]; then
  echo "!! Nie znaleziono AppImage w release." >&2
  exit 1
fi

echo "==> Instalacja do $BIN_DIR ..."
mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR"
install -m 0755 "$TMP_DIR/$FILE" "$BIN_DIR/$APP_NAME.AppImage"

cat > "$BIN_DIR/audacity" <<'EOF'
#!/usr/bin/env bash
APP="$HOME/.local/bin/Audacity.AppImage"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
export QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-gl}"
export LSP_WS_LIB_GLXSURFACE="${LSP_WS_LIB_GLXSURFACE:-off}"
if command -v fusermount3 >/dev/null 2>&1; then
  exec "$APP" "$@"
else
  exec "$APP" --appimage-extract-and-run "$@"
fi
EOF
chmod 0755 "$BIN_DIR/audacity"

echo "==> Wpis w menu KDE ..."
cat > "$APP_DIR/org.audacityteam.Audacity4portablenightly.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Audacity 4 (Pi5)
GenericName=Edytor dźwięku
Comment=Audacity 4 — build aarch64 pod Raspberry Pi 5
Exec=$BIN_DIR/audacity %F
Icon=audacity
Terminal=false
Categories=AudioVideo;Audio;AudioEditing;
StartupWMClass=audacity4portablenightly
EOF
rm -f "$APP_DIR/audacity.desktop"

curl -sL --fail -o "$ICON_DIR/audacity.svg" \
  "https://raw.githubusercontent.com/audacity/audacity/master/buildscripts/packaging/Linux%2BBSD/aup4.svg" || true

if command -v kbuildsycoca6 >/dev/null 2>&1; then kbuildsycoca6 >/dev/null 2>&1 || true; fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true; fi

echo ""
echo "OK. Uruchomienie: audacity"
