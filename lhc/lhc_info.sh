#!/bin/bash
# Prints some status data from the Large Hadron Collider.

set -e -u

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
cd "$TMP_DIR"

if ! wget --quiet --tries=1 --timeout=5 http://vistar-capture.web.cern.ch/vistar-capture/lhc1.png; then
    echo 'LHC data is currently unavailable.'
    exit 0
fi
convert lhc1.png -negate lhc1.png
convert lhc1.png -crop 1016x54+4+38 -monochrome -scale '200%' title.png
convert lhc1.png -crop 192x43+142+108 beam_energy.png
convert lhc1.png -crop 509x173+2+557 -scale '200%' comments.png

TITLE=$(gocr -d 0 -C 'A-Z0-9_:;,./--' -s 25 -i title.png | head -n 1)
ENERGY=$(gocr -d 0 -C '0-9MGeV' -i beam_energy.png | grep '^[0-9]\+ [a-zA-Z]\+$' | head -n 1)
COMMENTS=$(gocr -d 0 -C 'ABCDEFGHJKLMNOPQRSTUVWXYZa-z0-9_:;,./--' -s 23 -i comments.png)
COMMENTS="${COMMENTS//$'\n'/, }"
COMMENTS=$(printf '%s' "$COMMENTS" | sed 's/\(, \)\{2,\}/. /g')

if [[ ! $ENERGY ]]; then
    printf '%s. No beam. %s\n' "$TITLE" "$COMMENTS"
else
    printf '%s. Beam energy: %s. %s\n' "$TITLE" "$ENERGY" "$COMMENTS"
fi

exit 0