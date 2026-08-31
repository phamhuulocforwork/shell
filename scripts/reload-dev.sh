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

pkill -x qs 2>/dev/null || true
sleep 1
setsid env QT_QPA_PLATFORMTHEME=gtk3 \
	qs -c caelestia -d \
	> /tmp/qs-fork-test.log 2>&1 < /dev/null &
sleep 5
echo "errors: $(grep -icE 'error|exception' /tmp/qs-fork-test.log)"
