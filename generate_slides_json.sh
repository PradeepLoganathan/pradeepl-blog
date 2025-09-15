#!/bin/bash

# Define paths
STATIC_SLIDES_DIR="static/slides"
DATA_DIR="data"
OUTPUT_FILE="$DATA_DIR/slides_folders.json"

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Find directories inside static/slides (only one level deep), strip trailing slashes
slide_folders=$(find "$STATIC_SLIDES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

# Convert list of folder names to JSON array
json_array=$(printf '%s\n' "$slide_folders" | jq -R . | jq -s .)

# Save to output file
echo "$json_array" > "$OUTPUT_FILE"

echo "Generated $OUTPUT_FILE with slide folders:"
echo "$json_array"
