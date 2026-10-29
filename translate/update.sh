#!/bin/sh
# Refresh template.pot from the i18n() calls in contents/ and merge it into every <lang>.po, so new strings
# show up untranslated and removed ones are marked obsolete. Compiling the .po files is compile.sh's job.
#
# Usage:
#   translate/update.sh   refresh template.pot and every <lang>.po
#
# To start a new language (de here), run update.sh, then:
#   msginit --no-translator --locale=de --input=translate/template.pot --output=translate/de.po
# and fill in its msgstr lines.
#
# Needs xgettext, msgmerge and msgfmt from gettext.

set -e
cd "$(dirname "$0")/.."

log() {
    echo "[translate] $*"
}

fail() {
    echo "[translate] ERROR: $*" >&2
    exit 1
}

require_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "'$1' not found, needed to update the translations (package gettext)"
}

log "Checking tools..."
require_tool xgettext
require_tool msgmerge
require_tool msgfmt

SOURCES=$(find contents -name '*.qml' | sort)
SOURCE_COUNT=$(echo "$SOURCES" | wc -l)
log "Extracting i18n() strings from $SOURCE_COUNT .qml files in contents/..."

# $SOURCES is split on purpose: one argument per file.
# shellcheck disable=SC2086
xgettext \
    --from-code=UTF-8 \
    --language=JavaScript \
    --keyword=i18n \
    --keyword=i18nc:1c,2 \
    --keyword=i18np:1,2 \
    --keyword=i18ncp:1c,2,3 \
    --package-name="Process List" \
    --msgid-bugs-address="https://github.com/moxwel/processlist-plasmoid/issues" \
    --output=translate/template.pot \
    $SOURCES

MESSAGE_COUNT=$(grep -c '^msgid ' translate/template.pot)
log "  wrote translate/template.pot ($((MESSAGE_COUNT - 1)) messages)"

LANG_COUNT=0
for po in translate/*.po; do
    [ -e "$po" ] || continue
    log "Merging template.pot into $po..."
    msgmerge --quiet --update --backup=none "$po" translate/template.pot
    log "  $(msgfmt --statistics -o /dev/null "$po" 2>&1)"
    LANG_COUNT=$((LANG_COUNT + 1))
done

if [ "$LANG_COUNT" -eq 0 ]; then
    log "WARNING: no translate/*.po files found, only template.pot was refreshed."
fi
log "Done: template.pot and $LANG_COUNT language(s) updated."
