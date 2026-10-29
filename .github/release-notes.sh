#!/bin/sh
# Print the CHANGELOG.md text under the "# <tag>" heading, up to the next "# " heading, so the release
# workflow can use it verbatim as the GitHub release notes. Fails if the version has no text.
#
# Usage:
#   .github/release-notes.sh <tag>   e.g. .github/release-notes.sh v1.0.1

set -e
cd "$(dirname "$0")/.."

TAG=${1:?usage: $0 <tag>}

NOTES=$(awk -v heading="# $TAG" '
    $0 == heading { isInSection = 1; next }
    /^# / { isInSection = 0 }
    isInSection { print }
' CHANGELOG.md)

if [ -z "$(echo "$NOTES" | tr -d '[:space:]')" ]; then
    echo "ERROR: no notes for $TAG in CHANGELOG.md, add a \"# $TAG\" section" >&2
    exit 1
fi

echo "$NOTES"
