#!/bin/bash
#
# --- Recursive File Content Aggregator (multi-pattern) ---
#
# Usage:
#   ./context_gathering.sh <search_directory> <output_file> <pattern1> [pattern2 … patternN]
#
# Example:
#   ./context_gathering.sh . context.txt "docker-compose.yml" ".env.template"

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <search_directory> <output_file> <pattern1> [pattern2 …]"
    exit 1
fi

SEARCH_DIR=$1
OUTPUT_FILE=$2
shift 2
PATTERNS=("$@")      # all remaining args

if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: Directory '$SEARCH_DIR' not found."
    exit 1
fi

echo "Searching '$SEARCH_DIR' for patterns: ${PATTERNS[*]}"
echo "Writing results to: $OUTPUT_FILE"
> "$OUTPUT_FILE"

# Build the find-expr: -name "p1" -o -name "p2" …
find_expr=()
for p in "${PATTERNS[@]}"; do
    find_expr+=( -name "$p" -o )
done
# remove trailing '-o'
unset 'find_expr[${#find_expr[@]}-1]'

# Run find and concatenate
find "$SEARCH_DIR" -type f \( "${find_expr[@]}" \) | while IFS= read -r file; do
    rel=$(realpath --relative-to="$SEARCH_DIR" "$file")
    echo "Found: $rel"
    echo "--- Content of: $rel ---" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
done

if [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Done! Combined content in '$OUTPUT_FILE'."
else
    echo "⚠️ No files matched. Removing empty '$OUTPUT_FILE'."
    rm "$OUTPUT_FILE"
fi
