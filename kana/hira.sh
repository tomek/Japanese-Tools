#!/bin/bash
# Copyright: Christoph Dittmann <github@christoph-d.de>
# License: GNU GPL, version 3 or later; http://www.gnu.org/copyleft/gpl.html
#
# Hiragana trainer.

DIRECTORY="$(dirname "$0")"
KANA_FILE="$DIRECTORY/hiragana.txt"
IRC_COMMAND='!hira'

. "$(dirname "$0")/kana.sh"
