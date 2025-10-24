#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
F="$ROOT/out/filtered.tsv"

mkdir -p "$ROOT/out"

echo "Starting Step 5: String Structure Analysis..."
echo "Input: $F"
echo ""

if [[ ! -f "$F" ]]; then
    echo "Error: Input file $F not found. Run Step 3 first." >&2
    exit 1
fi

# ---- 1) Artist name length buckets ----
echo "1. Analyzing artist name length distribution..."
awk -F'\t' -v OFS='\t' '
NR==1 { next }  # Skip header
{
    artist = $1
    len = length(artist)
    if (len <= 10) {
        buckets["SHORT"]++
    } else if (len <= 20) {
        buckets["MEDIUM"]++
    } else {
        buckets["LONG"]++
    }
    total_len += len
    count++
}
END {
    printf "length_bucket\tcount\tavg_length\n"
    printf "SHORT\t%d\t%.2f\n", buckets["SHORT"]+0, (buckets["SHORT"] ? total_len/count : 0)
    printf "MEDIUM\t%d\t%.2f\n", buckets["MEDIUM"]+0, (buckets["MEDIUM"] ? total_len/count : 0)
    printf "LONG\t%d\t%.2f\n", buckets["LONG"]+0, (buckets["LONG"] ? total_len/count : 0)
    printf "TOTAL\t%d\t%.2f\n", count, (count ? total_len/count : 0)
}' "$F" > "$ROOT/out/artist_name_length_buckets.tsv"

echo ""
echo "Step 5 completed successfully!"
echo "[task5] wrote:"
echo " - $ROOT/out/artist_name_length_buckets.tsv"
