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
# Needs xgettext and msgmerge from gettext.

set -e
cd "$(dirname "$0")/.."

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
    $(find contents -name '*.qml' | sort)

for po in translate/*.po; do
    [ -e "$po" ] || continue
    msgmerge --quiet --update --backup=none "$po" translate/template.pot
done
