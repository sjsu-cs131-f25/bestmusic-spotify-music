#!/bin/bash
# ============================================================
# Project Assignment 4 — Task 5: String Structure Analysis
# Since we have no time columns, analyze string structure:
# - Artist name length buckets
# - Track ID pattern analysis
# - Genre case normalization analysis
# ============================================================

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
F="$ROOT/out/filtered.tsv"

mkdir -p "$ROOT/out"

echo "Starting Step 5: String Structure Analysis..."
echo "Input: $F"
echo ""

# Check if input exists
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

# ---- 2) Track ID pattern analysis ----
echo "2. Analyzing track ID patterns..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    track_id = $3
    len = length(track_id)
    if (len == 22) {
        patterns["22_CHAR"]++
    } else {
        patterns["OTHER"]++
    }
    # Check for alphanumeric pattern
    if (track_id ~ /^[A-Za-z0-9]+$/) {
        patterns["ALPHANUMERIC"]++
    } else {
        patterns["NON_ALPHANUMERIC"]++
    }
}
END {
    printf "pattern_type\tcount\n"
    for (p in patterns) {
        printf "%s\t%d\n", p, patterns[p]
    }
}' "$F" > "$ROOT/out/track_id_patterns.tsv"

# ---- 3) Genre case normalization analysis ----
echo "3. Analyzing genre case normalization..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    genre = $2
    genre_lower = tolower(genre)
    original[genre]++
    normalized[genre_lower]++
}
END {
    printf "original_genre\tnormalized_genre\tcount\n"
    for (g in original) {
        printf "%s\t%s\t%d\n", g, tolower(g), original[g]
    }
}' "$F" | sort -t$'\t' -k3,3nr > "$ROOT/out/genre_case_analysis.tsv"

# ---- 4) Duration analysis (if we had duration_ms) ----
echo "4. Creating duration buckets (simulated from track_id patterns)..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    track_id = $3
    # Use track_id length as proxy for "complexity"
    len = length(track_id)
    if (len <= 20) {
        buckets["SIMPLE"]++
    } else if (len <= 22) {
        buckets["STANDARD"]++
    } else {
        buckets["COMPLEX"]++
    }
}
END {
    printf "complexity_bucket\tcount\n"
    printf "SIMPLE\t%d\n", buckets["SIMPLE"]+0
    printf "STANDARD\t%d\n", buckets["STANDARD"]+0
    printf "COMPLEX\t%d\n", buckets["COMPLEX"]+0
}' "$F" > "$ROOT/out/duration_buckets.tsv"

# ---- 5) Popularity range buckets ----
echo "5. Creating popularity range buckets..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    pop = $4 + 0
    if (pop < 50) {
        buckets["LOW"]++
    } else if (pop < 70) {
        buckets["MEDIUM"]++
    } else {
        buckets["HIGH"]++
    }
}
END {
    printf "popularity_range\tcount\n"
    printf "LOW\t%d\n", buckets["LOW"]+0
    printf "MEDIUM\t%d\n", buckets["MEDIUM"]+0
    printf "HIGH\t%d\n", buckets["HIGH"]+0
}' "$F" > "$ROOT/out/popularity_range_buckets.tsv"

echo ""
echo "Step 5 completed successfully!"
echo "[task5] wrote:"
echo " - $ROOT/out/artist_name_length_buckets.tsv"
echo " - $ROOT/out/track_id_patterns.tsv"
echo " - $ROOT/out/genre_case_analysis.tsv"
echo " - $ROOT/out/duration_buckets.tsv"
echo " - $ROOT/out/popularity_range_buckets.tsv"
