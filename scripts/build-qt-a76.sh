#!/usr/bin/env bash
# ============================================================================
# Budowa Qt 6.10.1 ZE ŹRÓDEŁ — pod Raspberry Pi 5 (Cortex-A76) + NATYWNY Wayland
# ----------------------------------------------------------------------------
# Dlaczego:
#   * prebuilt Qt z aqt ma ZEPSUTĄ inicjalizację pluginu wayland (ładuje się,
#     ale Qt i tak spada na xcb/XWayland) — nie da się naprawić programowo
#   * build ze źródeł daje Qt w 100% pod A76 (-mcpu=cortex-a76 -O3) — domyka
#     lukę "Qt generyczne arm64" z prebuiltów
# Użycie w CI: ubuntu-24.04-arm, gcc, ninja, ccache
# Wynik: prefix Qt w $QT_PREFIX (Qt6_DIR dla buildu Audacity)
# ============================================================================
set -euo pipefail

QT_VERSION="${QT_VERSION:-6.10.1}"
QT_DIR="${QT_DIR:-$HOME/Qt-src}"
PREFIX="${QT_PREFIX:-$HOME/Qt/${QT_VERSION}/gcc_arm64}"
JOBS="$(nproc)"
CCACHE="${CCACHE:-ccache}"

# Optymalizacja pod Cortex-A76 (RPi5 / BCM2712)
OPT_FLAGS="-mcpu=cortex-a76 -O3 -pipe -fomit-frame-pointer"

# Moduły w kolejności zależnościowej (jak w aqt: qt5compat qtnetworkauth
# qtshadertools qtwebsockets qtgraphs qtquick3d) + qtbase/qtwayland/qtdeclarative
MODULES=(qtbase qtshadertools qtdeclarative qtquicktimeline qtquick3d qtgraphs qt5compat qtnetworkauth qtwebsockets qtwayland)

# Jeśli Qt już w prefixie — pomiń (szybsze iteracje / cache)
if [ -f "$PREFIX/lib/cmake/Qt6/Qt6Config.cmake" ]; then
  echo "==> Qt $QT_VERSION już w $PREFIX — pomijam budowę."
  exit 0
fi

mkdir -p "$QT_DIR" "$PREFIX"
cd "$QT_DIR"

for MOD in "${MODULES[@]}"; do
  TARBALL="${MOD}-everywhere-src-${QT_VERSION}.tar.xz"
  SRC_DIR="${MOD}-everywhere-src-${QT_VERSION}"
  URL="https://download.qt.io/official_releases/qt/${QT_VERSION%.*}/${QT_VERSION}/submodules/${TARBALL}"
  LOG="${QT_DIR}/qt-build-${MOD}.log"

  echo "=== [Qt] $MOD: pobieranie ==="
  if [ ! -f "$TARBALL" ]; then
    curl -L --fail --retry 3 -o "$TARBALL" "$URL"
  fi
  if [ ! -d "$SRC_DIR" ]; then
    tar -xf "$TARBALL"
  fi

  echo "=== [Qt] $MOD: konfiguracja (log: $LOG) ==="
  rm -rf "$SRC_DIR/build"
  mkdir -p "$SRC_DIR/build"
  pushd "$SRC_DIR/build" >/dev/null

  CONF_COMMON=(
    -release
    -opensource -confirm-license
    -prefix "$PREFIX"
    -nomake examples -nomake tests
    -no-pch
    -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_C_COMPILER_LAUNCHER="$CCACHE"
    -DCMAKE_CXX_COMPILER_LAUNCHER="$CCACHE"
    -DCMAKE_C_FLAGS="${OPT_FLAGS}"
    -DCMAKE_CXX_FLAGS="${OPT_FLAGS}"
    -DCMAKE_PREFIX_PATH="$PREFIX"
  )
  if [ "$MOD" = "qtbase" ]; then
    # Wayland client (natywny plugin libqwayland) + xcb (fallback)
    CONF_COMMON+=(-feature-wayland-client)
  fi

  if ! ../configure "${CONF_COMMON[@]}" >"$LOG" 2>&1; then
    echo "!! [Qt] $MOD: BŁĄD konfiguracji (ostatnie 30 linii $LOG):" >&2
    tail -30 "$LOG" >&2
    exit 1
  fi

  echo "=== [Qt] $MOD: build (-j$JOBS) ==="
  if ! cmake --build . --parallel "$JOBS" >>"$LOG" 2>&1; then
    echo "!! [Qt] $MOD: BŁĄD buildu (ostatnie 30 linii $LOG):" >&2
    tail -30 "$LOG" >&2
    exit 1
  fi

  echo "=== [Qt] $MOD: install ==="
  cmake --install . >>"$LOG" 2>&1
  popd >/dev/null

  # zwolnij miejsce na dysku (14GB SSD runnera) — źródła/build już niepotrzebne
  rm -rf "$SRC_DIR" "$TARBALL"
  echo "=== [Qt] $MOD: OK ==="
done

echo "==> Qt $QT_VERSION zbudowane w $PREFIX"
"$PREFIX/bin/qmake6" -query QT_VERSION
"$PREFIX/bin/qtpaths6" --qt-version 2>/dev/null || true
