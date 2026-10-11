#!/bin/bash

set -euo pipefail
POSTS_DIR="/var/www/posts/posts"
OUTPUT="/var/www/posts/index.html"

html_escape() {
    local text="$1"
    text="${text//&\&amp;}"
    text="${text//<\&lt;}"
    text="${text//>\&gt;}"
    text="${text//\"\&quot;}"
    printf '%s' "$text"
}

markdown_to_html() {
    local line
    local in_paragraph=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -z "$line" ]]; then
            if (( in_paragraph )); then
                printf '</p>\n'
                in_paragraph=0
            fi
            continue
        fi
        line=$(html_escape "$line")
        if [[ "$line" =~ ^######[[:space:]]+(.*)$ ]]; then
            if (( in_paragraph )); then
                printf '</p>\n'
                in_paragraph=0
            fi
            printf '<h6>%s</h6>\n' "${BASH_REMATCH[1]}"
            continue
        elif [[ "$line" =~ ^#####[[:space:]]+(.*)$ ]]; then
            if (( in_paragraph )); then
                printf '</p>\n'
                in_paragraph=0
            fi
            printf '<h5>%s</h5>\n' "${BASH_REMATCH[1]}"
            continue
        elif [[ "$line" =~ ^####[[:space:]]+(.*)$ ]]; then
            if (( in_paragraph )); then
                printf '</p>\n'
                in_paragraph=0
            fi
            printf '<h4>%s</h4>\n' "${BASH_REMATCH[1]}"
            continue
        elif [[ "$line" =~ ^###[[:space:]]+(.*)$ ]]; then
            if (( in_paragraph )); then
                printf '</p>\n'
                in_paragraph=0
            fi
            printf '<h3>%s</h3>\n' "${BASH_REMATCH[1]}"
            continue
        elif [[ "$line" =~ ^##[[:space:]]+(.*)$ ]]; then
            if (( in_paragraph )); then
                printf '</p>\n'
                in_paragraph=0
            fi
            printf '<h2>%s</h2>\n' "${BASH_REMATCH[1]}"
            continue
        elif [[ "$line" =~ ^#[[:space:]]+(.*)$ ]]; then
            if (( in_paragraph )); then
                printf '</p>\n'
                in_paragraph=0
            fi
            printf '<h1>%s</h1>\n' "${BASH_REMATCH[1]}"
            continue
        fi
        line=$(printf '%s' "$line" |
            sed -E 's/`([^`]*)`/<code>\1<\/code>/g')
        line=$(printf '%s' "$line" |
            sed -E 's/\*\*([^*]+)\*\*/<strong>\1<\/strong>/g')
        line=$(printf '%s' "$line" |
            sed -E 's/~~([^~]+)~~/<del>\1<\/del>/g')
        line=$(printf '%s' "$line" |
            sed -E 's/\*([^*]+)\*/<em>\1<\/em>/g')
        if (( ! in_paragraph )); then
            printf '<p>'
            in_paragraph=1
        else
            printf '\n'
        fi
        printf '%s' "$line"
    done
    if (( in_paragraph )); then
        printf '</p>\n'
    fi
}

pretty_date() {
    local filename="$1"
    local month="${filename:0:2}"
    local day="${filename:2:2}"
    local year="${filename:4:2}"
    local month_name
    case "$month" in
        01) month_name="January" ;;
        02) month_name="February" ;;
        03) month_name="March" ;;
        04) month_name="April" ;;
        05) month_name="May" ;;
        06) month_name="June" ;;
        07) month_name="July" ;;
        08) month_name="August" ;;
        09) month_name="September" ;;
        10) month_name="October" ;;
        11) month_name="November" ;;
        12) month_name="December" ;;
        *)
            echo "ERROR: Invalid month in filename: $filename" >&2
            return 1
            ;;
    esac
    printf '%s %d, 20%s' \
        "$month_name" \
        "$((10#$day))" \
        "$year"
}

if [[ ! -d "$POSTS_DIR" ]]; then
    echo "ERROR: '$POSTS_DIR' directory does not exist." >&2
    echo "Create it with:" >&2
    echo "    mkdir -p $POSTS_DIR" >&2
    exit 1
fi
posts=()
while IFS= read -r file; do
    posts+=("$file")
done < <(
    find "$POSTS_DIR" \
        -maxdepth 1 \
        -type f \
        -name '*.txt' \
        -print |
    awk -F/ '

        {
            file = $NF
            name = file
            sub(/\.txt$/, "", name)
            if (name ~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/) {
                date = substr(name, 1, 6)
                suffix = substr(name, 7, 1)
                yy = substr(date, 5, 2)
                mm = substr(date, 1, 2)
                dd = substr(date, 3, 2)
                printf "%s%s%s%s\t%s\n", yy, mm, dd, suffix, $0
            }
        }
    ' |
    sort -r |
    cut -f2-
)

cat > "$OUTPUT" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>What's new @ CIF?</title>
    <style>
        html,
        body {
            margin: 0;
            padding: 0;
            min-height: 100%;
            background-color: #0f0f0f;
            color: #ffffff;
            font-size: 20px;
        }
        body {
            font-family: "Courier New", Courier, monospace;
            line-height: 1.6;
        }
        #root {
            width: 90%;
            max-width: 900px;
            margin: 0 auto;
            padding: 30px 20px;
        }
        #header {
            margin-bottom: 50px;
            text-align: center;
            color: #00ff00;
        }
        #header-title {
            font-size: 1.75rem;
            margin-bottom: 5px;
        }
        #header-subtitle {
            color: #ffffff;
            font-size: 1rem;
        }
        .post {
            margin-bottom: 35px;
            padding: 25px 30px;

            background-color: #151515;
            border: 2px solid #00ff00;
            border-radius: 24px;
        }
        .post-date {
            margin-bottom: 20px;
            padding-bottom: 10px;
            color: #00ff00;
            font-size: 0.9rem;
            border-bottom: 1px solid #006600;
        }
        .post-content {
            color: #ffffff;
        }
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            color: #00ff00;
            line-height: 1.3;
        }
        h1 {
            font-size: 1.7rem;
        }
        h2 {
            font-size: 1.5rem;
        }
        h3 {
            font-size: 1.3rem;
        }
        h4,
        h5,
        h6 {
            font-size: 1.1rem;
        }
        p {
            margin: 0 0 1.2em;
        }
        strong {
            color: #00ff00;
        }
        em {
            font-style: italic;
        }
        del {
            color: #777777;
        }
        code {
            padding: 2px 5px;
            color: #00ff00;
            background-color: #000000;
            border: 1px solid #333333;
            border-radius: 4px;
            font-family: "Courier New", Courier, monospace;
            font-size: 0.9em;
        }

        #footer {
            margin-top: 50px;
            padding-top: 20px;

            color: #777777;
            border-top: 1px solid #333333;

            text-align: center;
            font-size: 0.8rem;
        }
        .post-author {
            margin-top: 20px;
            padding-top: 10px;
            color: #777777;
            font-size: 0.8rem;
            border-top: 1px solid #333333;
            text-align: right;
        }
        @media screen and (max-width: 600px) {
            html,
            body {
                font-size: 17px;
            }
            #root {
                width: auto;
                padding: 20px 10px;
            }
            #header {
                margin-bottom: 30px;
            }
            #header-title {
                font-size: 1.4rem;
            }
            .post {
                padding: 20px;
                border-radius: 18px;
            }
        }
    </style>
</head>
<body>
<div id="root">
    <div id="header">
        <div id="header-title">What's New @ CIF?</div>
        <div id="header-subtitle">
            What's going on in the CIF lab?
        </div>
    </div>
    <div id="mainBody">
HTML

for file in "${posts[@]}"; do
    filename=$(basename "$file" .txt)
    if [[ ! "$filename" =~ ^[0-9]{7}$ ]]; then
        echo "Skipping invalid filename: $file" >&2
        continue
    fi
    month="${filename:0:2}"
    day="${filename:2:2}"
    if (( 10#$month < 1 || 10#$month > 12 )); then
        echo "Skipping invalid date: $file" >&2
        continue
    fi
    if (( 10#$day < 1 || 10#$day > 31 )); then
        echo "Skipping invalid date: $file" >&2
        continue
    fi
    date=$(pretty_date "$filename")
    date_code="${filename:0:6}"
    suffix="${filename:6:1}"

    count=0

    for n in {0..9}; do
        [[ -f "$POSTS_DIR/${date_code}${n}.txt" ]] &&
            ((count += 1))
    done
    if (( count > 1 )); then
        number=$((10#$suffix + 1))
        date="$date -- $number"
    fi
    owner=$(stat -c '%U' "$file")
    cat >> "$OUTPUT" <<HTML

<article class="post">

    <div class="post-date">
        $date
    </div>
     <div class="post-content">

HTML
    if [[ -s "$file" ]]; then
        markdown_to_html < "$file" >> "$OUTPUT"
    else
        echo '    <p><em>(This post is empty.)</em></p>' \
            >> "$OUTPUT"
    fi
    cat >> "$OUTPUT" <<HTML
    <div class="post-author">
            Posted by: $(html_escape ""$owner"")
        </div>
    </div>
</article>
HTML
done
cat >> "$OUTPUT" <<'HTML'
</div>

    <div id="footer">
        Whoah, you made it all the way down here?  Thanks for reading my ramblings!<br>  Merry CIF-ing to all, and to all a good Morning?
    </div>
</main>
</body>
</html>
HTML
echo "Generated: $OUTPUT"
echo "Posts:     ${#posts[@]}"
