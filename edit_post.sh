#!/bin/bash

#Edits posts made.

set -euo pipefail
POSTS_DIR="/var/www/posts/posts"
GENERATOR="/var/www/posts/posts.sh"
if [[ ! -d "$POSTS_DIR" ]]; then
    echo "ERROR: Posts directory not found: $POSTS_DIR" >&2
    exit 1
fi

if [[ ! -x "$GENERATOR" ]]; then
    echo "ERROR: Generator missing or not executable: $GENERATOR" >&2
    exit 1
fi
mapfile -t POSTS < <(
    find "$POSTS_DIR" -maxdepth 1 -type f \
        -regextype posix-extended \
        -regex '.*/[0-9]{7}\.txt' -printf '%f\n' |
    sort -k1.5,1.6r -k1.1,1.4r -k1.7,1r
)
if (( ${#POSTS[@]} == 0 )); then
    echo "No posts found."
    exit 0
fi

pretty_date() {
    local f="$1"
    date -d "20${f:4:2}-${f:0:2}-${f:2:2}" "+%B %-d, %Y"
}

LABELS=()
for filename in "${POSTS[@]}"; do
    label=$(pretty_date "$filename")
    author=$(stat -c '%U' "$POSTS_DIR/$filename")
#    label+=" -- $author"
    count=0
    for f in "${POSTS[@]}"; do
        if [[ "${f:0:6}" == "${filename:0:6}" ]]; then
            count=$((count + 1))
        fi
    done
    if (( count > 1 )); then
        label+=", $((10#${filename:6:1} + 1))"
    fi
    label+=" -- $author"
    LABELS+=("$label")
done

selected=0
first=0

while true; do
    rows=$(tput lines)
    visible=$((rows - 5))
    (( visible < 1 )) && visible=1
    if (( selected < first )); then
        first=$selected
    elif (( selected >= first + visible )); then
        first=$((selected - visible + 1))
    fi
    clear
    echo "Select a post to edit (Select with arrows & enter, q to quit):"
    echo
    last=$((first + visible))
    (( last > ${#POSTS[@]} )) && last=${#POSTS[@]}

    for ((i = first; i < last; i++)); do
        if (( i == selected )); then
            printf "> %s\n" "${LABELS[$i]}"
        else
            printf "  %s\n" "${LABELS[$i]}"
        fi
    done
    echo
    printf "Showing %d-%d of %d posts\n" \
        "$((first + 1))" "$last" "${#POSTS[@]}"
    key=""
    IFS= read -rsn1 key || break
    if [[ "$key" == $'\x1b' ]]; then
        rest=""
        IFS= read -rsn2 -t 1 rest || true
        key="ESC$rest"
    fi
    case "$key" in
        ESC[A)
            if (( selected > 0 )); then
                selected=$((selected - 1))
            fi
            ;;
        ESC[B)
            if (( selected < ${#POSTS[@]} - 1 )); then
                selected=$((selected + 1))
            fi
            ;;
        "")
            post="$POSTS_DIR/${POSTS[$selected]}"
            clear
            echo "Editing: $post"
            nano "$post"
            clear
            echo "Regenerating website..."
            if "$GENERATOR"; then
                echo "Website regenerated successfully."
            else
                echo "ERROR: Website generation failed." >&2
                read -r -p "Press Enter to exit..."
                exit 1
            fi
            echo "Done. Exiting."
            exit 0
            ;;
        q|Q|ESC)
            clear
            exit 0
            ;;
    esac
done
clear
