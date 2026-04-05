#!/bin/bash
# Convert all levels/*.lua into a single levels.json for GitHub Pages hosting
# Run: ./tools/build-levels-json.sh
# Output: docs/levels.json

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LEVELS_DIR="$PROJECT_DIR/levels"
OUTPUT="$PROJECT_DIR/docs/levels.json"

mkdir -p "$PROJECT_DIR/docs"
echo "Building levels.json..."

VERSION=$(date +%Y%m%d%H%M%S)

{
echo "{"
echo "  \"version\": \"$VERSION\","
echo "  \"levels\": ["

first_level=true

for f in $(ls "$LEVELS_DIR"/level*.lua | sort -V); do
    # Extract level id
    level_id=$(sed -n 's/.*id *= *\([0-9]*\).*/\1/p' "$f" | head -1)
    # Extract exit row
    exit_row=$(sed -n 's/.*row *= *\([0-9]*\).*/\1/p' "$f" | head -1)

    if [ "$first_level" = true ]; then
        first_level=false
    else
        echo "    ,"
    fi

    echo "    {"
    echo "      \"id\": $level_id,"
    echo "      \"exit\": { \"side\": \"right\", \"row\": $exit_row },"
    echo "      \"cars\": ["

    # Extract each car line and convert to JSON
    first_car=true
    # Use grep to find car definition lines, handle variable whitespace
    grep 'id *=' "$f" | grep 'type *=' | while IFS= read -r line; do
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
    done

    echo "      ]"
    echo -n "    }"
done

echo ""
echo "  ]"
echo "}"

} > "$OUTPUT"

level_count=$(grep -c '"exit":' "$OUTPUT")
# Write version file separately for lightweight version check
echo -n "$VERSION" > "$PROJECT_DIR/docs/levels-version.txt"

echo "Created: docs/levels.json ($level_count levels)"
echo "Created: docs/levels-version.txt (version: $VERSION)"
