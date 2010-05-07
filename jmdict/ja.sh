#!/bin/bash
# Copyright: Christoph Dittmann <github@christoph-d.de>
# License: GNU GPL, version 3 or later; http://www.gnu.org/copyleft/gpl.html
#
# Dictionary lookup for Japanese words.

set -u

DICT=$(dirname "$0")/JMdict_e_prepared
MAX_RESULTS_PER_PATTERN=5
MAX_LENGTH_PER_ENGLISH=150
MAX_LINE_LENGTH=400
MAX_LINES=2
NOT_FOUND_MSG="Unknown word."

if [ ! -e "$DICT" ]; then
   echo "Please run: wget http://ftp.monash.edu.au/pub/nihongo/JMdict_e.gz && ./prepare_jmdict.sh JMdict_e.gz > JMdict_e_prepared"
   exit 1
fi

# Get query and remove backslashes because we use them internally.
QUERY=${@//\\/}

if [ -z "$QUERY" ]; then
    echo "epsilon."
    exit 0
fi

print_result() {
    # Change $IFS to loop over lines instead of words.
    ORIGIFS=$IFS
    IFS=$'\n'
    SEEN=
    LINE_COUNT=0
    for R in $RESULT; do
        # Skip duplicate lines.
        if echo "$SEEN" | grep -qF "$R"; then
            continue
        fi
        SEEN=$(echo "$SEEN" ; echo "$R")

        KANJI=$(echo "$R" | cut -d '\' -f 1)
        KANA=$(echo "$R" | cut -d '\' -f 2)
        POS=$(echo "$R" | cut -d '\' -f 3)
        ENGLISH=$(echo "$R" | cut -d '\' -f 4)
        if [ -n "$KANJI" ]; then
            L="$KANJI [$KANA] ($POS)"
        else
            L="$KANA ($POS)"
        fi
        if [ ${#ENGLISH} -gt $MAX_LENGTH_PER_ENGLISH ]; then
            ENGLISH="${ENGLISH:0:$(expr $MAX_LENGTH_PER_ENGLISH - 3)}..."
        fi
        CURRENT_ITEM="$L, $ENGLISH"
        NEXT="${LINE_BUFFER:+$LINE_BUFFER / }$CURRENT_ITEM"

        # If the final string would get too long, we're done.
        if [[ ${#NEXT} -gt $MAX_LINE_LENGTH ]]; then
            # Append the current line to the result.
            FINAL="${FINAL:+$FINAL\n}$LINE_BUFFER"
            # Remember the current item for the next line.
            NEXT="$CURRENT_ITEM"
            let ++LINE_COUNT
            [[ $LINE_COUNT -ge $MAX_LINES ]] && break
        fi
        LINE_BUFFER=$NEXT
    done
    IFS=$ORIGIFS
    if [[ $LINE_COUNT -lt $MAX_LINES ]]; then
        FINAL="${FINAL:+$FINAL\n}$LINE_BUFFER"
    fi

    echo -e "$FINAL"
}

# The more specific search patterns are used first.
PATTERNS=(
    # Perfect match.
    "\(\\\\\|^\)$QUERY\(\$\|\\\\\)"
    # Match primary kana reading.
    "^[^\\]*\\\\$QUERY\(,\|\\\\\)"
    # Match secondary kana readings.
    "^[^\\]*\\\\[^\\]*,$QUERY\(,\|\\\\\)"
    # Match "1. $QUERY (possibly something in brackets),".
    "\\\\\(1\\. \)$QUERY\( ([^,]*\?)\)\?,"
    # Match "1. $QUERY " or "1. $QUERY,".
    "\\\\\(1\\. \)\?$QUERY\( \|,\)"
    # Match $QUERY at the beginning of an entry (Kanji, Kana or English).
    "\(\\\\\|^\)\(1\\. \)\?$QUERY"
    # Match $QUERY at second position in the English definition.
    "2\\. $QUERY\( ([^,]*\?)\)\?\(,\|\$\)"
    # Match $QUERY everywhere.
    "$QUERY"
    )

# Accumulate results over all patterns.
RESULT=
for I in $(seq 0 1 $(expr ${#PATTERNS[@]} - 1)); do
    P="${PATTERNS[$I]}"
    RESULT=$(echo "$RESULT" ; grep -m $MAX_RESULTS_PER_PATTERN -e "$P" "$DICT")
done

if [ -n "$RESULT" ]; then
    print_result
else
    echo "$NOT_FOUND_MSG"
fi

exit 0