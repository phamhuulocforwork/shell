#!/usr/bin/env bash
# Reload the dev fork at ~/.config/quickshell/caelestia.
# Usage:
#   scripts/reload-dev.sh          # QML-only changes (fast path)
#   scripts/reload-dev.sh plugin   # after editing plugin/ C++ sources
set -e
cd "$(dirname "$0")/.."

if [ "${1:-}" = "plugin" ]; then
	cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
	cmake --build build
	sudo cmake --install build
	sudo chown -R "$USER" "$HOME/.config/quickshell/caelestia"
fi

# Restart only the dev-fork instance. A bare `pkill -x qs` would also kill the
# separate overview process (~/.config/quickshell/overview), so target this
# config by path. `-c caelestia` resolves here too now that the
# ~/.config/quickshell/shell.qml default symlink is gone.
CFG="$HOME/.config/quickshell/caelestia/shell.qml"
qs -p "$CFG" kill >/dev/null 2>&1 || true
sleep 1
setsid env QT_QPA_PLATFORMTHEME=gtk3 \
	qs -p "$CFG" -n -d \
	> /tmp/qs-fork-test.log 2>&1 < /dev/null &
sleep 5
echo "errors: $(grep -icE 'error|exception' /tmp/qs-fork-test.log)"
