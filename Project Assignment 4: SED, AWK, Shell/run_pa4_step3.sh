#!/bin/bash

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/out"
LOG_DIR="$SCRIPT_DIR/logs"

# Input and output files
INPUT_FILE="$OUTPUT_DIR/artist_popularity_skinny.tsv"
OUTPUT_FILE="$OUTPUT_DIR/filtered.tsv"
LOG_FILE="$LOG_DIR/step3.log"

MIN_POPULARITY=40

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

echo "Starting Step 3: Quality Filters..."
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo "Rules: artist != '', popularity >= $MIN_POPULARITY, drop test/dummy/sample"
echo ""

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file $INPUT_FILE not found. Run Step 2 first." >&2
    exit 1
fi

# Apply quality filters using AWK
# Structure: artist_name, genre, track_id, popularity, energy, danceability
awk -F'\t' -v OFS='\t' -v min_pop="$MIN_POPULARITY" '
BEGIN {
    print "artist_name\tgenre\ttrack_id\tpopularity\tenergy\tdanceability"
    IGNORECASE=1
}
{
    artist = $1
    genre = $2
    track_id = $3
    popularity = $4 + 0
    energy = $5 + 0
    danceability = $6 + 0
    
    # Business rules
    req_ok = (artist != "" && popularity != "")
    pop_ok = (popularity >= min_pop)
    test_hit = (artist ~ /(test|dummy|sample)/)
    keep = (req_ok && pop_ok && !test_hit)
    
    if (keep) {
        printf "%s\t%s\t%s\t%d\t%.4f\t%.4f\n", 
               artist, genre, track_id, popularity, energy, danceability
    }
}' "$INPUT_FILE" > "$OUTPUT_FILE"

# Generate statistics
total_rows=$(($(wc -l < "$INPUT_FILE")))
kept_rows=$(($(wc -l < "$OUTPUT_FILE") - 1))  # Subtract header
dropped_rows=$((total_rows - kept_rows))

{
    echo "Step 3: Quality Filters Results"
    echo "================================"
    echo "Total input rows: $total_rows"
    echo "Rows kept: $kept_rows"
    echo "Rows dropped: $dropped_rows"
    echo "Filtered data saved to: $OUTPUT_FILE"
    echo ""
    echo "Sample of filtered data:"
    head -5 "$OUTPUT_FILE"
} | tee "$LOG_FILE"

echo ""
echo "Step 3 completed successfully!"
echo "Filtered data ready for Step 4 (Ratios, Buckets, and Per-Artist Summary)"
