#!/bin/sh
# Install, upgrade or remove the two Process List widgets (CPU and RAM), then reload plasmashell. Installing
# runs build.sh first and installs the package folders it writes to build/.
#
# Usage:
#   ./install.sh           install both widgets, or upgrade them if they are already installed
#   ./install.sh remove    uninstall both widgets
#
# Needs zip, and msgfmt from gettext.

set -e
cd "$(dirname "$0")"

ACTION=${1:-install}
case "$ACTION" in
    install|remove) ;;
    *) echo "usage: $0 [install|remove]" >&2; exit 1 ;;
esac

if [ "$ACTION" = install ]; then
    ./build.sh
fi

ID_TEMPLATE=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' metadata.json)

for mode in cpu ram; do
    PLUGIN_ID=$(echo "$ID_TEMPLATE" | sed "s/@MODE@/$mode/g")

    if [ "$ACTION" = remove ]; then
        echo "Removing $PLUGIN_ID..."
        kpackagetool6 -t Plasma/Applet --remove "$PLUGIN_ID" || true
        continue
    fi

    echo "Installing $PLUGIN_ID..."
    kpackagetool6 -t Plasma/Applet --upgrade "build/$PLUGIN_ID" >/dev/null 2>&1 \
        || kpackagetool6 -t Plasma/Applet --install "build/$PLUGIN_ID"
done

echo "Reloading plasmashell..."
systemctl --user restart plasma-plasmashell.service
