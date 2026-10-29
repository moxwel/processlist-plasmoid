#!/bin/sh
# Install, upgrade or remove the two Process List widgets (CPU and RAM), then reload plasmashell. Installing
# runs build.sh first and installs the package folders it writes to build/.
#
# Usage:
#   ./install.sh           install both widgets, or upgrade them if they are already installed
#   ./install.sh remove    uninstall both widgets
#
# Needs kpackagetool6, zip and msgfmt from gettext.

set -e
cd "$(dirname "$0")"

log() {
    echo "[install] $*"
}

fail() {
    echo "[install] ERROR: $*" >&2
    exit 1
}

ACTION=${1:-install}
case "$ACTION" in
    install|remove) ;;
    *) fail "unknown action '$ACTION', usage: $0 [install|remove]" ;;
esac

log "Action: $ACTION"
command -v kpackagetool6 >/dev/null 2>&1 || fail "'kpackagetool6' not found, needed to manage Plasma widgets"

if [ "$ACTION" = install ]; then
    log "Building the widgets first..."
    ./build.sh
fi

log "Reading metadata.json..."
ID_TEMPLATE=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' metadata.json)
[ -n "$ID_TEMPLATE" ] || fail "no \"Id\" found in metadata.json"
log "  id template: $ID_TEMPLATE"

MODES="cpu ram"
MODE_COUNT=$(echo "$MODES" | wc -w)
MODE_INDEX=0

for mode in $MODES; do
    MODE_INDEX=$((MODE_INDEX + 1))
    PLUGIN_ID=$(echo "$ID_TEMPLATE" | sed "s/@MODE@/$mode/g")

    if [ "$ACTION" = remove ]; then
        log "[$MODE_INDEX/$MODE_COUNT] Removing $PLUGIN_ID..."
        if kpackagetool6 -t Plasma/Applet --remove "$PLUGIN_ID"; then
            log "  removed $PLUGIN_ID"
        else
            log "  $PLUGIN_ID was not installed or could not be removed, continuing"
        fi
        continue
    fi

    [ -d "build/$PLUGIN_ID" ] || fail "package folder build/$PLUGIN_ID not found, the build did not produce it"
    log "[$MODE_INDEX/$MODE_COUNT] Installing $PLUGIN_ID from build/$PLUGIN_ID..."
    log "  trying to upgrade an existing install"
    if kpackagetool6 -t Plasma/Applet --upgrade "build/$PLUGIN_ID" >/dev/null 2>&1; then
        log "  upgraded $PLUGIN_ID"
    else
        log "  not installed yet, installing"
        kpackagetool6 -t Plasma/Applet --install "build/$PLUGIN_ID"
        log "  installed $PLUGIN_ID"
    fi
done

log "Reloading plasmashell..."
systemctl --user restart plasma-plasmashell.service
log "  plasmashell restarted"

log "Done."
echo ""
