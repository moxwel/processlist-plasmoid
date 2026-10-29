#!/bin/sh
# Build the two Process List widgets (CPU and RAM) from contents/. Each one gets a package folder,
# build/<Id>/, with its mode, label and icon placeholders filled in and its translations compiled, and a
# .plasmoid file of that folder ready to share or upload to the KDE Store. install.sh installs the folders.
#
# Usage:
#   ./build.sh   write build/<Id>/ and build/processlist-<mode>.plasmoid for each widget
#
# Needs zip, and msgfmt from gettext.

set -e
cd "$(dirname "$0")"

log() {
    echo "[build] $*"
}

fail() {
    echo "[build] ERROR: $*" >&2
    exit 1
}

# Stops the build unless a tool is installed. Takes the tool name and what the build needs it for.
require_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "'$1' not found, needed to $2"
    log "  found $1: $(command -v "$1")"
}

log "Checking tools..."
require_tool zip "pack the .plasmoid files"
require_tool msgfmt "compile the translations (package gettext)"

log "Reading metadata.json..."
ID_TEMPLATE=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' metadata.json)
[ -n "$ID_TEMPLATE" ] || fail "no \"Id\" found in metadata.json"
log "  id template: $ID_TEMPLATE"

MODES="cpu ram"
MODE_COUNT=$(echo "$MODES" | wc -w)
MODE_INDEX=0

for mode in $MODES; do
    MODE_INDEX=$((MODE_INDEX + 1))
    case "$mode" in
        cpu) LABEL=CPU ICON=cpu ;;
        ram) LABEL=RAM ICON=memory ;;
    esac
    PLUGIN_ID=$(echo "$ID_TEMPLATE" | sed "s/@MODE@/$mode/g")
    PACKAGE_DIR="build/$PLUGIN_ID"
    OUTPUT="build/processlist-$mode.plasmoid"

    log "[$MODE_INDEX/$MODE_COUNT] Building $PLUGIN_ID (mode=$mode, label=$LABEL, icon=$ICON)..."

    log "  cleaning $PACKAGE_DIR and $OUTPUT"
    rm -rf "$PACKAGE_DIR" "$OUTPUT"
    mkdir -p "$PACKAGE_DIR/contents"

    log "  copying contents/ and LICENSE to $PACKAGE_DIR"
    cp -r contents/* "$PACKAGE_DIR/contents/"
    cp LICENSE "$PACKAGE_DIR/"

    log "  filling @MODE@ in contents/ui/*.qml"
    sed -i "s/@MODE@/$mode/g" "$PACKAGE_DIR"/contents/ui/*.qml
    log "  filling @ICON@ in contents/config/main.xml"
    sed -i "s/@ICON@/$ICON/" "$PACKAGE_DIR/contents/config/main.xml"
    log "  writing $PACKAGE_DIR/metadata.json (@MODE@, @LABEL@, @ICON@)"
    sed "s/@MODE@/$mode/g; s/@LABEL@/$LABEL/g; s/@ICON@/$ICON/g" metadata.json > "$PACKAGE_DIR/metadata.json"

    log "  compiling translations"
    translate/compile.sh "$PACKAGE_DIR"

    log "  packing $OUTPUT"
    (cd "$PACKAGE_DIR" && zip -qr "../processlist-$mode.plasmoid" metadata.json contents LICENSE)
    log "  packed $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"

    log "[$MODE_INDEX/$MODE_COUNT] Built $PLUGIN_ID."
done

log "Output:"
for mode in $MODES; do
    log "  build/processlist-$mode.plasmoid"
done
log "Done."
