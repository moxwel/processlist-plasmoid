#!/bin/sh
# Compile every translate/<lang>.po into a built widget's contents/locale/, where Plasma looks up its
# translations.
#
# Usage:
#   translate/compile.sh <package dir>   compile into <package dir>/contents/locale/
#
# Needs msgfmt from gettext.

set -e

PACKAGE_DIR=$(cd "${1:?usage: $0 <package dir>}" && pwd)
cd "$(dirname "$0")/.."

PLUGIN_ID=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' "$PACKAGE_DIR/metadata.json")
LOCALE_DIR="$PACKAGE_DIR/contents/locale"

echo "Compiling translations..."
for po in translate/*.po; do
    [ -e "$po" ] || continue
    lang=$(basename "$po" .po)
    mkdir -p "$LOCALE_DIR/$lang/LC_MESSAGES"
    msgfmt --check -o "$LOCALE_DIR/$lang/LC_MESSAGES/plasma_applet_$PLUGIN_ID.mo" "$po"
done
