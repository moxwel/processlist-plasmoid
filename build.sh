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

ID_TEMPLATE=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' metadata.json)

for mode in cpu ram; do
    case "$mode" in
        cpu) LABEL=CPU ICON=cpu ;;
        ram) LABEL=RAM ICON=memory ;;
    esac
    PLUGIN_ID=$(echo "$ID_TEMPLATE" | sed "s/@MODE@/$mode/g")
    PACKAGE_DIR="build/$PLUGIN_ID"
    OUTPUT="build/processlist-$mode.plasmoid"

    echo "Building $PLUGIN_ID..."
    rm -rf "$PACKAGE_DIR" "$OUTPUT"
    mkdir -p "$PACKAGE_DIR/contents"
    cp -r contents/* "$PACKAGE_DIR/contents/"
    cp LICENSE "$PACKAGE_DIR/"
    sed -i "s/@MODE@/$mode/g" "$PACKAGE_DIR"/contents/ui/*.qml
    sed -i "s/@ICON@/$ICON/" "$PACKAGE_DIR/contents/config/main.xml"
    sed "s/@MODE@/$mode/g; s/@LABEL@/$LABEL/g; s/@ICON@/$ICON/g" metadata.json > "$PACKAGE_DIR/metadata.json"
    translate/compile.sh "$PACKAGE_DIR"

    (cd "$PACKAGE_DIR" && zip -qr "../processlist-$mode.plasmoid" metadata.json contents LICENSE)
    echo "Built $OUTPUT"
done
