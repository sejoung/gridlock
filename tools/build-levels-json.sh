#!/bin/bash
# Convert all levels/*.lua into a single levels.json for GitHub Pages hosting
# Run: ./tools/build-levels-json.sh
# Output: docs/levels.json, docs/levels-version.txt

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LEVELS_DIR="$PROJECT_DIR/levels"
OUTPUT="$PROJECT_DIR/docs/levels.json"

mkdir -p "$PROJECT_DIR/docs"
echo "Building levels.json..."

VERSION=$(date +%Y%m%d%H%M%S)

# Build JSON by reading each level file carefully
{
echo "{"
echo "  \"version\": \"$VERSION\","
echo "  \"levels\": ["

first_level=true

for f in $(ls "$LEVELS_DIR"/level*.lua | sort -V); do
    # Level id: match "id = <number>," at the top of the file (before cars block)
    # Only match lines where id has a plain number value, not a string like "goal"
    level_id=$(grep -m1 'id *= *[0-9]' "$f" | grep -v '"' | sed 's/.*id *= *\([0-9]*\).*/\1/')
    exit_row=$(grep -m1 'row *= *[0-9]' "$f" | sed 's/.*row *= *\([0-9]*\).*/\1/')

    if [ -z "$level_id" ] || [ -z "$exit_row" ]; then
        echo "  WARNING: Skipping $f (missing id or exit row)" >&2
        continue
    fi

    if [ "$first_level" = true ]; then
        first_level=false
    else
        echo "    ,"
    fi

    echo "    {"
    echo "      \"id\": $level_id,"
    echo "      \"exit\": { \"side\": \"right\", \"row\": $exit_row },"
    echo "      \"cars\": ["

    # Extract car lines: must contain both 'type' and 'dir' (distinguishes from level metadata)
    # Write cars to temp file to avoid subshell variable issues
    tmpfile=$(mktemp)
    grep 'type *=' "$f" | grep 'dir *=' > "$tmpfile" || true

    first_car=true
    while IFS= read -r line; do
        car_id=$(echo "$line" | sed 's/.*id *= *"\([^"]*\)".*/\1/')
        car_x=$(echo "$line" | sed 's/.*x *= *\([0-9]*\).*/\1/')
        car_y=$(echo "$line" | sed 's/.*y *= *\([0-9]*\).*/\1/')
        car_dir=$(echo "$line" | sed 's/.*dir *= *"\([HV]\)".*/\1/')
        car_type=$(echo "$line" | sed 's/.*type *= *"\([^"]*\)".*/\1/')

        if [ "$first_car" = true ]; then
            first_car=false
        else
            echo "        ,"
        fi
        printf '        { "id": "%s", "x": %s, "y": %s, "dir": "%s", "type": "%s" }' \
            "$car_id" "$car_x" "$car_y" "$car_dir" "$car_type"
        echo ""
    done < "$tmpfile"
    rm -f "$tmpfile"

    echo "      ]"
    echo -n "    }"
done

echo ""
echo "  ]"
echo "}"

} > "$OUTPUT"

# Version file
echo -n "$VERSION" > "$PROJECT_DIR/docs/levels-version.txt"

level_count=$(grep -c '"exit":' "$OUTPUT")
echo "Created: docs/levels.json ($level_count levels)"
echo "Created: docs/levels-version.txt (version: $VERSION)"
