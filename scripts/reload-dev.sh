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

# Sync the cmake-installed shell at /etc/xdg, which is what "caelestia shell -d"
# loads on boot (the default ~/.config/quickshell/shell.qml symlink suppresses
# registration of the caelestia/ subdir, so -c caelestia falls through to /etc/xdg).
sudo rsync -a --delete assets components modules services utils LICENSE /etc/xdg/quickshell/caelestia/
sed 's/settings.watchFiles: true/settings.watchFiles: false/' shell.qml | sudo tee /etc/xdg/quickshell/caelestia/shell.qml > /dev/null

pkill -x qs 2>/dev/null || true
sleep 1
setsid env QT_QPA_PLATFORMTHEME=gtk3 \
	qs -p "$HOME/.config/quickshell/caelestia/shell.qml" -n -d \
	> /tmp/qs-fork-test.log 2>&1 < /dev/null &
sleep 5
echo "errors: $(grep -icE 'error|exception' /tmp/qs-fork-test.log)"
