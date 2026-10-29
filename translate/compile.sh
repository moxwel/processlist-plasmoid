#!/bin/sh
# Compile every translate/<lang>.po into a built widget's contents/locale/, where Plasma looks up its
# translations.
#
# Usage:
#   translate/compile.sh <package dir>   compile into <package dir>/contents/locale/
#
# Needs msgfmt from gettext.

set -e

log() {
    echo "[translate] $*"
}

fail() {
    echo "[translate] ERROR: $*" >&2
    exit 1
}

[ -n "$1" ] || fail "missing <package dir>, usage: $0 <package dir>"
[ -d "$1" ] || fail "package dir '$1' not found"
command -v msgfmt >/dev/null 2>&1 || fail "'msgfmt' not found, needed to compile the translations (package gettext)"

PACKAGE_DIR=$(cd "$1" && pwd)
cd "$(dirname "$0")/.."

[ -f "$PACKAGE_DIR/metadata.json" ] || fail "'$PACKAGE_DIR/metadata.json' not found, build the package first"
PLUGIN_ID=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' "$PACKAGE_DIR/metadata.json")
[ -n "$PLUGIN_ID" ] || fail "no \"Id\" found in $PACKAGE_DIR/metadata.json"
LOCALE_DIR="$PACKAGE_DIR/contents/locale"

log "Plugin: $PLUGIN_ID"
log "Output: $LOCALE_DIR/<lang>/LC_MESSAGES/plasma_applet_$PLUGIN_ID.mo"

LANG_COUNT=0
for po in translate/*.po; do
    [ -e "$po" ] || continue
    lang=$(basename "$po" .po)
    mo="$LOCALE_DIR/$lang/LC_MESSAGES/plasma_applet_$PLUGIN_ID.mo"

    log "Compiling $po (lang=$lang)..."
    mkdir -p "$LOCALE_DIR/$lang/LC_MESSAGES"
    if ! STATS=$(msgfmt --check --statistics -o "$mo" "$po" 2>&1); then
        echo "$STATS" >&2
        fail "msgfmt rejected $po"
    fi
    log "  $STATS"
    log "  wrote $mo"
    LANG_COUNT=$((LANG_COUNT + 1))
done

if [ "$LANG_COUNT" -eq 0 ]; then
    log "WARNING: no translate/*.po files found, nothing compiled."
fi
log "Done: $LANG_COUNT language(s) compiled."
