#!/bin/bash

# This is the new script to make posts.  It uses a slightly different format than the old one, allowing for 10 posts per day to be made!  : )

set -euo pipefail
POSTS_DIR="/var/www/posts/posts"
GENERATOR="/var/www/posts/posts.sh"

#FILENAME="$(date '+%m%d%y').txt"
#POST="$POSTS_DIR/$FILENAME"
if [[ ! -d "$POSTS_DIR" ]]; then
    echo "ERROR: Posts directory does not exist:"
    echo "  $POSTS_DIR"
    exit 1
fi
if [[ ! -x "$GENERATOR" ]]; then
    echo "ERROR: Generator script does not exist or is not executable:"
    echo "  $GENERATOR"
    exit 1
fi
DATE_CODE="$(date '+%m%d%y')"
POST=""
for n in {0..9}; do
    candidate="$POSTS_DIR/${DATE_CODE}${n}.txt"
    if [[ ! -e "$candidate" ]]; then
        POST="$candidate"
        break
    fi
done
if [[ -z "$POST" ]]; then
    echo "ERROR: All 10 post filenames for today are in use." >&2
    exit 1
fi
( set -o noclobber; : > "$POST" )
chmod 644 "$POST"
echo "Editing: $POST"
nano "$POST"
echo "Generating website..."
"$GENERATOR"
echo "Done."
